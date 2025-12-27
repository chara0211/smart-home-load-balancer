# Solution Définitive pour les Pods Non Prêts
# Ce script résout TOUS les problèmes de pods non prêts de manière systématique
# Usage: .\scripts\solution-definitive-pods-ready.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SOLUTION DÉFINITIVE - PODS NON PRÊTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "smarthome"
$ErrorActionPreference = "Continue"

# Fonction pour attendre qu'un pod soit prêt
function Wait-ForPodReady {
    param(
        [string]$PodName,
        [int]$TimeoutSeconds = 300,
        [string]$Namespace = "smarthome"
    )
    
    $elapsed = 0
    $interval = 5
    
    while ($elapsed -lt $TimeoutSeconds) {
        $pod = kubectl get pod -n $Namespace $PodName -o json 2>$null | ConvertFrom-Json
        if ($pod -and $pod.status.containerStatuses[0].ready -eq $true) {
            return $true
        }
        Start-Sleep -Seconds $interval
        $elapsed += $interval
        Write-Host "   En attente... ($elapsed/$TimeoutSeconds secondes)" -ForegroundColor Gray
    }
    return $false
}

# ÉTAPE 1 : Nettoyer TOUS les pods en erreur
Write-Host "ÉTAPE 1: NETTOYAGE DES PODS EN ERREUR" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

# Supprimer tous les pods en CrashLoopBackOff
Write-Host "Suppression des pods en CrashLoopBackOff..." -ForegroundColor Cyan
$crashLoopPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$crashLoopPods = $crashLoopPods.items | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
}

foreach ($pod in $crashLoopPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --ignore-not-found=true --grace-period=0 --force 2>$null
}

# Supprimer tous les pods en Error
Write-Host "Suppression des pods en Error..." -ForegroundColor Cyan
$errorPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$errorPods = $errorPods.items | Where-Object { $_.status.phase -eq "Failed" }

foreach ($pod in $errorPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --ignore-not-found=true --grace-period=0 --force 2>$null
}

# Supprimer tous les pods en Pending
Write-Host "Suppression des pods en Pending..." -ForegroundColor Cyan
$pendingPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$pendingPods = $pendingPods.items | Where-Object { $_.status.phase -eq "Pending" }

foreach ($pod in $pendingPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --ignore-not-found=true --grace-period=0 --force 2>$null
}

Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 5

# ÉTAPE 2 : Vérifier et corriger les ressources
Write-Host "ÉTAPE 2: VÉRIFICATION DES RESSOURCES" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Write-Host "Vérification de l'espace disque et des ressources..." -ForegroundColor Cyan
kubectl top nodes 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  kubectl top n'est pas disponible. Vérifiez manuellement les ressources." -ForegroundColor Yellow
}

# Vérifier les nœuds
$nodes = kubectl get nodes -o json | ConvertFrom-Json
foreach ($node in $nodes.items) {
    $nodeName = $node.metadata.name
    $ready = ($node.status.conditions | Where-Object { $_.type -eq "Ready" }).status
    Write-Host "   Nœud $nodeName : $(if ($ready -eq 'True') { '✅ Prêt' } else { '❌ Non prêt' })" -ForegroundColor $(if ($ready -eq 'True') { 'Green' } else { 'Red' })
}

Write-Host ""

# ÉTAPE 3 : Corriger PostgreSQL (PRIORITÉ ABSOLUE)
Write-Host "ÉTAPE 3: CORRECTION DE POSTGRESQL (PRIORITÉ)" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Write-Host "PostgreSQL est critique - tous les services en dépendent" -ForegroundColor Cyan

# Supprimer le pod PostgreSQL actuel
$postgresPod = kubectl get pods -n $namespace -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($postgresPod) {
    Write-Host "Suppression du pod PostgreSQL actuel: $postgresPod" -ForegroundColor Cyan
    kubectl delete pod -n $namespace $postgresPod --grace-period=0 --force 2>$null
    Start-Sleep -Seconds 10
}

# Vérifier le PVC
Write-Host "Vérification du PersistentVolumeClaim..." -ForegroundColor Cyan
$pvc = kubectl get pvc -n $namespace postgres-pvc -o json 2>$null | ConvertFrom-Json
if (-not $pvc) {
    Write-Host "⚠️  PVC postgres-pvc introuvable. Création..." -ForegroundColor Yellow
    kubectl apply -f k8s/databases/postgres-deployment.yaml
} else {
    $pvcStatus = $pvc.status.phase
    Write-Host "   PVC Status: $pvcStatus" -ForegroundColor $(if ($pvcStatus -eq 'Bound') { 'Green' } else { 'Red' })
}

# Appliquer la configuration améliorée de PostgreSQL
Write-Host "Application de la configuration PostgreSQL améliorée..." -ForegroundColor Cyan
kubectl apply -f k8s/databases/postgres-deployment.yaml

# Attendre que PostgreSQL démarre
Write-Host "Attente que PostgreSQL démarre (timeout: 5 minutes)..." -ForegroundColor Cyan
$postgresReady = $false
$timeout = 300
$elapsed = 0
$interval = 10

while ($elapsed -lt $timeout) {
    $postgresPod = kubectl get pods -n $namespace -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($postgresPod) {
        $podStatus = kubectl get pod -n $namespace $postgresPod -o jsonpath='{.status.phase}' 2>$null
        $containerReady = kubectl get pod -n $namespace $postgresPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
        
        if ($podStatus -eq "Running" -and $containerReady -eq "true") {
            Write-Host "✅ PostgreSQL est prêt !" -ForegroundColor Green
            $postgresReady = $true
            break
        }
        
        if ($podStatus -eq "CrashLoopBackOff" -or $podStatus -eq "Error") {
            Write-Host "❌ PostgreSQL a des problèmes. Vérification des logs..." -ForegroundColor Red
            kubectl logs -n $namespace $postgresPod --tail=20 2>&1 | Select-Object -Last 10 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
            Write-Host "   Nouvelle tentative de redémarrage..." -ForegroundColor Yellow
            kubectl delete pod -n $namespace $postgresPod --grace-period=0 --force 2>$null
            Start-Sleep -Seconds 10
        }
    }
    
    Write-Host "   En attente... ($elapsed/$timeout secondes) - Status: $podStatus" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if (-not $postgresReady) {
    Write-Host "❌ PostgreSQL n'est pas prêt après 5 minutes" -ForegroundColor Red
    Write-Host "Vérifiez les logs: kubectl logs -n $namespace -l app=postgres --tail=50" -ForegroundColor Yellow
    Write-Host "Vérifiez les événements: kubectl describe pod -n $namespace -l app=postgres" -ForegroundColor Yellow
}

Write-Host ""

# ÉTAPE 4 : Corriger RabbitMQ
Write-Host "ÉTAPE 4: CORRECTION DE RABBITMQ" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

# Supprimer le pod RabbitMQ actuel
$rabbitmqPod = kubectl get pods -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($rabbitmqPod) {
    Write-Host "Suppression du pod RabbitMQ actuel: $rabbitmqPod" -ForegroundColor Cyan
    kubectl delete pod -n $namespace $rabbitmqPod --grace-period=0 --force 2>$null
    Start-Sleep -Seconds 10
}

# Appliquer la configuration améliorée de RabbitMQ
Write-Host "Application de la configuration RabbitMQ améliorée..." -ForegroundColor Cyan
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml

# Attendre que RabbitMQ démarre
Write-Host "Attente que RabbitMQ démarre (timeout: 5 minutes)..." -ForegroundColor Cyan
$rabbitmqReady = $false
$timeout = 300
$elapsed = 0
$interval = 10

while ($elapsed -lt $timeout) {
    $rabbitmqPod = kubectl get pods -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($rabbitmqPod) {
        $podStatus = kubectl get pod -n $namespace $rabbitmqPod -o jsonpath='{.status.phase}' 2>$null
        $containerReady = kubectl get pod -n $namespace $rabbitmqPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
        
        if ($podStatus -eq "Running" -and $containerReady -eq "true") {
            Write-Host "✅ RabbitMQ est prêt !" -ForegroundColor Green
            $rabbitmqReady = $true
            break
        }
    }
    
    Write-Host "   En attente... ($elapsed/$timeout secondes) - Status: $podStatus" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if (-not $rabbitmqReady) {
    Write-Host "⚠️  RabbitMQ n'est pas prêt après 5 minutes" -ForegroundColor Yellow
    Write-Host "Vérifiez les logs: kubectl logs -n $namespace -l app=rabbitmq --tail=50" -ForegroundColor Yellow
}

Write-Host ""

# ÉTAPE 5 : Attendre que les dépendances soient prêtes
Write-Host "ÉTAPE 5: ATTENTE DES DÉPENDANCES CRITIQUES" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Write-Host "Vérification que PostgreSQL et RabbitMQ sont prêts..." -ForegroundColor Cyan
$allDepsReady = $false
$maxWait = 300
$elapsed = 0
$interval = 10

while (-not $allDepsReady -and $elapsed -lt $maxWait) {
    $postgresReady = kubectl get pod -n $namespace -l app=postgres -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
    $rabbitmqReady = kubectl get pod -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
    
    if ($postgresReady -eq "true" -and $rabbitmqReady -eq "true") {
        $allDepsReady = $true
        Write-Host "✅ Toutes les dépendances sont prêtes !" -ForegroundColor Green
        break
    }
    
    Write-Host "   PostgreSQL: $(if ($postgresReady -eq 'true') { '✅' } else { '❌' }) | RabbitMQ: $(if ($rabbitmqReady -eq 'true') { '✅' } else { '❌' })" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if (-not $allDepsReady) {
    Write-Host "⚠️  Les dépendances ne sont pas toutes prêtes" -ForegroundColor Yellow
    Write-Host "Continuez quand même avec le redémarrage des services..." -ForegroundColor Yellow
}

Write-Host ""

# ÉTAPE 6 : Redémarrer tous les services Spring Boot
Write-Host "ÉTAPE 6: REDÉMARRAGE DES SERVICES SPRING BOOT" -ForegroundColor Yellow
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
    
    # Supprimer tous les pods du service
    $pods = kubectl get pods -n $namespace -l app=$service -o jsonpath='{.items[*].metadata.name}' 2>$null
    if ($pods) {
        $podsArray = $pods -split ' '
        foreach ($pod in $podsArray) {
            if ($pod) {
                kubectl delete pod -n $namespace $pod --grace-period=0 --force 2>$null
            }
        }
    }
    
    # Redémarrer le déploiement
    kubectl rollout restart deployment/$service -n $namespace 2>$null
    Start-Sleep -Seconds 3
}

Write-Host "✅ Tous les services ont été redémarrés" -ForegroundColor Green
Write-Host ""

# ÉTAPE 7 : Redémarrer Keycloak (si nécessaire)
Write-Host "ÉTAPE 7: VÉRIFICATION DE KEYCLOAK" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$keycloakPod = kubectl get pods -n $namespace -l app=keycloak -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($keycloakPod) {
    $keycloakStatus = kubectl get pod -n $namespace $keycloakPod -o jsonpath='{.status.phase}' 2>$null
    
    if ($keycloakStatus -eq "Error" -or $keycloakStatus -eq "CrashLoopBackOff") {
        Write-Host "Keycloak est en erreur. Redémarrage..." -ForegroundColor Yellow
        kubectl delete pod -n $namespace $keycloakPod --grace-period=0 --force 2>$null
        Write-Host "⚠️  Keycloak peut prendre 5-10 minutes pour démarrer complètement" -ForegroundColor Yellow
    } else {
        Write-Host "Keycloak Status: $keycloakStatus" -ForegroundColor Cyan
    }
} else {
    Write-Host "⚠️  Pod Keycloak introuvable" -ForegroundColor Yellow
}

Write-Host ""

# ÉTAPE 8 : État final et recommandations
Write-Host "ÉTAPE 8: ÉTAT FINAL" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Write-Host "État actuel des pods:" -ForegroundColor Cyan
kubectl get pods -n $namespace
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SOLUTION APPLIQUÉE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Surveillez l'état des pods avec:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""
Write-Host "Vérifiez les logs si des pods ne démarrent pas:" -ForegroundColor Yellow
Write-Host "  kubectl logs -n $namespace <pod-name> --tail=50" -ForegroundColor White
Write-Host ""
Write-Host "Vérifiez les événements:" -ForegroundColor Yellow
Write-Host "  kubectl get events -n $namespace --sort-by='.lastTimestamp' | Select-Object -Last 30" -ForegroundColor White
Write-Host ""
Write-Host "Si des pods restent en Pending, vérifiez les ressources:" -ForegroundColor Yellow
Write-Host "  kubectl describe node" -ForegroundColor White
Write-Host "  kubectl top nodes" -ForegroundColor White
Write-Host ""
Write-Host "Si PostgreSQL ne démarre toujours pas:" -ForegroundColor Yellow
Write-Host "  kubectl describe pod -n $namespace -l app=postgres" -ForegroundColor White
Write-Host "  kubectl logs -n $namespace -l app=postgres --tail=100" -ForegroundColor White
Write-Host ""


