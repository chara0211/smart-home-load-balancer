# Script de correction pour les pods non prêts
# Usage: .\scripts\fix-pods-not-ready.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTION DES PODS NON PRÊTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "smarthome"

# 1. Corriger RabbitMQ (problème principal)
Write-Host "1. CORRECTION DE RABBITMQ" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$rabbitmqPod = kubectl get pods -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($rabbitmqPod) {
    Write-Host "RabbitMQ pod trouvé: $rabbitmqPod" -ForegroundColor Cyan
    Write-Host "RabbitMQ redémarre constamment à cause de problèmes de mémoire." -ForegroundColor Yellow
    Write-Host "Suppression du pod pour forcer un redémarrage propre..." -ForegroundColor Yellow
    kubectl delete pod -n $namespace $rabbitmqPod
    Write-Host "Attente que RabbitMQ redémarre..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Attendre que RabbitMQ soit prêt (avec timeout)
    Write-Host "Attente que RabbitMQ soit prêt (timeout: 5 minutes)..." -ForegroundColor Yellow
    $timeout = 300
    $elapsed = 0
    $interval = 10
    
    while ($elapsed -lt $timeout) {
        $rabbitmqReady = kubectl get pod -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
        if ($rabbitmqReady -eq "true") {
            Write-Host "✅ RabbitMQ est prêt !" -ForegroundColor Green
            break
        }
        Write-Host "   En attente... ($elapsed/$timeout secondes)" -ForegroundColor Gray
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }
    
    if ($elapsed -ge $timeout) {
        Write-Host "⚠️  Timeout: RabbitMQ n'est pas prêt après 5 minutes" -ForegroundColor Red
        Write-Host "Vérifiez les logs: kubectl logs -n $namespace -l app=rabbitmq --tail=50" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Pod RabbitMQ introuvable" -ForegroundColor Red
}

Write-Host ""

# 2. Corriger PostgreSQL
Write-Host "2. CORRECTION DE POSTGRESQL" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$postgresPod = kubectl get pods -n $namespace -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($postgresPod) {
    Write-Host "PostgreSQL pod trouvé: $postgresPod" -ForegroundColor Cyan
    $postgresReady = kubectl get pod -n $namespace $postgresPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
    
    if ($postgresReady -ne "true") {
        Write-Host "PostgreSQL n'est pas prêt. Redémarrage..." -ForegroundColor Yellow
        kubectl delete pod -n $namespace $postgresPod
        Write-Host "Attente que PostgreSQL redémarre..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Attendre que PostgreSQL soit prêt
        Write-Host "Attente que PostgreSQL soit prêt (timeout: 3 minutes)..." -ForegroundColor Yellow
        $timeout = 180
        $elapsed = 0
        $interval = 5
        
        while ($elapsed -lt $timeout) {
            $postgresReady = kubectl get pod -n $namespace -l app=postgres -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
            if ($postgresReady -eq "true") {
                Write-Host "✅ PostgreSQL est prêt !" -ForegroundColor Green
                break
            }
            Write-Host "   En attente... ($elapsed/$timeout secondes)" -ForegroundColor Gray
            Start-Sleep -Seconds $interval
            $elapsed += $interval
        }
        
        if ($elapsed -ge $timeout) {
            Write-Host "⚠️  Timeout: PostgreSQL n'est pas prêt après 3 minutes" -ForegroundColor Red
            Write-Host "Vérifiez les logs: kubectl logs -n $namespace -l app=postgres --tail=50" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✅ PostgreSQL est déjà prêt" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Pod PostgreSQL introuvable" -ForegroundColor Red
}

Write-Host ""

# 3. Vérifier Keycloak
Write-Host "3. VÉRIFICATION DE KEYCLOAK" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$keycloakPod = kubectl get pods -n $namespace -l app=keycloak -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($keycloakPod) {
    Write-Host "Keycloak pod trouvé: $keycloakPod" -ForegroundColor Cyan
    $keycloakReady = kubectl get pod -n $namespace $keycloakPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
    
    if ($keycloakReady -eq "true") {
        Write-Host "✅ Keycloak est prêt !" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Keycloak n'est pas encore prêt (peut prendre 5-10 minutes)" -ForegroundColor Yellow
        Write-Host "Vérifiez les logs: kubectl logs -n $namespace $keycloakPod --tail=20" -ForegroundColor Yellow
        Write-Host "Ne redémarrez PAS Keycloak s'il est en cours de construction !" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Pod Keycloak introuvable" -ForegroundColor Red
}

Write-Host ""

# 4. Supprimer les pods Pending (ils seront recréés automatiquement)
Write-Host "4. NETTOYAGE DES PODS PENDING" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$pendingPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$pendingPods = $pendingPods.items | Where-Object { $_.status.phase -eq "Pending" }

if ($pendingPods.Count -gt 0) {
    Write-Host "Suppression de $($pendingPods.Count) pod(s) en état Pending..." -ForegroundColor Yellow
    foreach ($pod in $pendingPods) {
        $podName = $pod.metadata.name
        Write-Host "   Suppression: $podName" -ForegroundColor Gray
        kubectl delete pod -n $namespace $podName --ignore-not-found=true
    }
    Write-Host "Les pods seront recréés automatiquement par les déploiements." -ForegroundColor Green
} else {
    Write-Host "Aucun pod en état Pending" -ForegroundColor Green
}

Write-Host ""

# 5. Attendre que les dépendances soient prêtes avant de redémarrer les services
Write-Host "5. ATTENTE DES DÉPENDANCES" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Write-Host "Attente que RabbitMQ et PostgreSQL soient prêts..." -ForegroundColor Yellow
$allReady = $false
$maxWait = 300  # 5 minutes
$elapsed = 0
$interval = 10

while (-not $allReady -and $elapsed -lt $maxWait) {
    $rabbitmqReady = kubectl get pod -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
    $postgresReady = kubectl get pod -n $namespace -l app=postgres -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
    
    if ($rabbitmqReady -eq "true" -and $postgresReady -eq "true") {
        $allReady = $true
        Write-Host "✅ Toutes les dépendances sont prêtes !" -ForegroundColor Green
        break
    }
    
    Write-Host "   RabbitMQ: $(if ($rabbitmqReady -eq 'true') { '✅' } else { '❌' }) | PostgreSQL: $(if ($postgresReady -eq 'true') { '✅' } else { '❌' })" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if (-not $allReady) {
    Write-Host "⚠️  Les dépendances ne sont pas toutes prêtes après 5 minutes" -ForegroundColor Red
    Write-Host "Continuez quand même avec le redémarrage des services..." -ForegroundColor Yellow
}

Write-Host ""

# 6. Redémarrer les services Spring Boot
Write-Host "6. REDÉMARRAGE DES SERVICES SPRING BOOT" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    Write-Host "Redémarrage de $service..." -ForegroundColor Cyan
    kubectl rollout restart deployment/$service -n $namespace
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "✅ Tous les services ont été redémarrés" -ForegroundColor Green
Write-Host ""

# 7. Afficher l'état final
Write-Host "7. ÉTAT FINAL DES PODS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTION TERMINÉE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Surveillez l'état des pods avec:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""
Write-Host "Vérifiez les logs si des pods ne démarrent pas:" -ForegroundColor Yellow
Write-Host "  kubectl logs -n $namespace <pod-name> --tail=50" -ForegroundColor White
Write-Host ""




