# Script de diagnostic pour les pods non prêts
# Usage: .\scripts\diagnostic-pods-not-ready.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSTIC DES PODS NON PRÊTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "smarthome"

# 1. Vérifier les pods non prêts
Write-Host "1. PODS NON PRÊTS (0/1 Ready):" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
kubectl get pods -n $namespace -o wide | Where-Object { $_ -match "0/1" -or $_ -match "Pending" }
Write-Host ""

# 2. Vérifier les événements récents
Write-Host "2. ÉVÉNEMENTS RÉCENTS (dernières 30 minutes):" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
kubectl get events -n $namespace --sort-by='.lastTimestamp' | Select-Object -Last 20
Write-Host ""

# 3. Vérifier les ressources disponibles
Write-Host "3. RESSOURCES DISPONIBLES DANS LE CLUSTER:" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
kubectl top nodes 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "kubectl top nodes n'est pas disponible. Vérifiez les ressources manuellement." -ForegroundColor Red
}
Write-Host ""

# 4. Diagnostiquer chaque pod non prêt
Write-Host "4. DIAGNOSTIC DÉTAILLÉ PAR POD:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Obtenir tous les pods non prêts
$pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$notReadyPods = $pods.items | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.ready -eq $false }
}

foreach ($pod in $notReadyPods) {
    $podName = $pod.metadata.name
    $status = $pod.status.phase
    Write-Host ""
    Write-Host "POD: $podName" -ForegroundColor Cyan
    Write-Host "Status: $status" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    # Vérifier si le pod est en Pending
    if ($status -eq "Pending") {
        Write-Host "⚠️  Pod en état Pending - Vérification des raisons..." -ForegroundColor Red
        
        # Vérifier les conditions
        if ($pod.status.conditions) {
            foreach ($condition in $pod.status.conditions) {
                if ($condition.type -eq "PodScheduled" -and $condition.status -eq "False") {
                    Write-Host "   Raison: $($condition.reason)" -ForegroundColor Red
                    Write-Host "   Message: $($condition.message)" -ForegroundColor Red
                }
            }
        }
        
        # Vérifier les événements spécifiques à ce pod
        Write-Host "   Événements récents:" -ForegroundColor Yellow
        kubectl get events -n $namespace --field-selector involvedObject.name=$podName --sort-by='.lastTimestamp' | Select-Object -Last 5
    }
    
    # Vérifier les conteneurs non prêts
    if ($pod.status.containerStatuses) {
        foreach ($container in $pod.status.containerStatuses) {
            if (-not $container.ready) {
                Write-Host "   Conteneur: $($container.name)" -ForegroundColor Yellow
                
                # Vérifier l'état du conteneur
                if ($container.state.waiting) {
                    Write-Host "   État: Waiting" -ForegroundColor Red
                    Write-Host "   Raison: $($container.state.waiting.reason)" -ForegroundColor Red
                    Write-Host "   Message: $($container.state.waiting.message)" -ForegroundColor Red
                }
                
                if ($container.state.running) {
                    Write-Host "   État: Running mais non prêt" -ForegroundColor Yellow
                    
                    # Vérifier les restart counts
                    if ($container.restartCount -gt 0) {
                        Write-Host "   ⚠️  Redémarrages: $($container.restartCount)" -ForegroundColor Red
                    }
                }
                
                # Vérifier les probes
                Write-Host "   Vérification des readiness probes..." -ForegroundColor Yellow
            }
        }
    }
    
    # Afficher les dernières lignes des logs
    Write-Host "   Dernières lignes des logs:" -ForegroundColor Yellow
    $logs = kubectl logs -n $namespace $podName --tail=20 2>&1
    if ($logs) {
        $logs | Select-Object -Last 10 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    } else {
        Write-Host "   (Pas de logs disponibles)" -ForegroundColor Gray
    }
}

# 5. Vérifier les dépendances critiques
Write-Host ""
Write-Host "5. VÉRIFICATION DES DÉPENDANCES:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# PostgreSQL
Write-Host "PostgreSQL:" -ForegroundColor Cyan
$postgresPod = kubectl get pods -n $namespace -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($postgresPod) {
    $postgresReady = kubectl get pod -n $namespace $postgresPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
    if ($postgresReady -eq "true") {
        Write-Host "   ✅ PostgreSQL est prêt" -ForegroundColor Green
    } else {
        Write-Host "   ❌ PostgreSQL n'est pas prêt" -ForegroundColor Red
        Write-Host "   Logs:" -ForegroundColor Yellow
        kubectl logs -n $namespace $postgresPod --tail=5 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "   ❌ Pod PostgreSQL introuvable" -ForegroundColor Red
}

# RabbitMQ
Write-Host "RabbitMQ:" -ForegroundColor Cyan
$rabbitmqPod = kubectl get pods -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($rabbitmqPod) {
    $rabbitmqReady = kubectl get pod -n $namespace $rabbitmqPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
    if ($rabbitmqReady -eq "true") {
        Write-Host "   ✅ RabbitMQ est prêt" -ForegroundColor Green
    } else {
        Write-Host "   ❌ RabbitMQ n'est pas prêt" -ForegroundColor Red
        Write-Host "   Logs:" -ForegroundColor Yellow
        kubectl logs -n $namespace $rabbitmqPod --tail=5 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "   ❌ Pod RabbitMQ introuvable" -ForegroundColor Red
}

# Keycloak
Write-Host "Keycloak:" -ForegroundColor Cyan
$keycloakPod = kubectl get pods -n $namespace -l app=keycloak -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($keycloakPod) {
    $keycloakReady = kubectl get pod -n $namespace $keycloakPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
    if ($keycloakReady -eq "true") {
        Write-Host "   ✅ Keycloak est prêt" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Keycloak n'est pas prêt (peut être en cours de construction)" -ForegroundColor Yellow
        Write-Host "   Logs:" -ForegroundColor Yellow
        kubectl logs -n $namespace $keycloakPod --tail=5 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "   ❌ Pod Keycloak introuvable" -ForegroundColor Red
}

# 6. Vérifier les services
Write-Host ""
Write-Host "6. VÉRIFICATION DES SERVICES:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
kubectl get svc -n $namespace
Write-Host ""

# 7. Vérifier les secrets et configmaps
Write-Host "7. VÉRIFICATION DES SECRETS ET CONFIGMAPS:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Secrets:" -ForegroundColor Cyan
kubectl get secrets -n $namespace
Write-Host ""
Write-Host "ConfigMaps:" -ForegroundColor Cyan
kubectl get configmaps -n $namespace
Write-Host ""

# 8. Résumé et recommandations
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RÉSUMÉ ET RECOMMANDATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Actions recommandées:" -ForegroundColor Yellow
Write-Host "1. Vérifier les logs des pods en erreur avec: kubectl logs -n $namespace <pod-name>" -ForegroundColor White
Write-Host "2. Vérifier les événements avec: kubectl describe pod -n $namespace <pod-name>" -ForegroundColor White
Write-Host "3. Pour les pods Pending, vérifier les ressources: kubectl describe node" -ForegroundColor White
Write-Host "4. Pour les pods Running mais non prêts, vérifier les readiness probes:" -ForegroundColor White
Write-Host "   kubectl get pod -n $namespace <pod-name> -o yaml | Select-String -Pattern 'readinessProbe' -Context 10" -ForegroundColor White
Write-Host "5. Tester les endpoints de santé manuellement:" -ForegroundColor White
Write-Host "   kubectl exec -n $namespace <pod-name> -- curl http://localhost:<port>/actuator/health/readiness" -ForegroundColor White
Write-Host ""




