# Script pour appliquer les corrections et redémarrer les services
# Usage: .\scripts\apply-fixes-and-restart.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "APPLICATION DES CORRECTIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "smarthome"

# 1. Appliquer la configuration RabbitMQ améliorée
Write-Host "1. Application de la configuration RabbitMQ améliorée..." -ForegroundColor Yellow
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
Write-Host "✅ Configuration RabbitMQ appliquée" -ForegroundColor Green
Write-Host ""

# 2. Appliquer les configurations améliorées des services Spring Boot
Write-Host "2. Application des configurations améliorées des services..." -ForegroundColor Yellow

$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    Write-Host "   Application de $service..." -ForegroundColor Cyan
    kubectl apply -f "k8s/services/$($service.Replace('-service', '').Replace('billing', 'billing') -replace '^(.+)$', '$1')/deployment.yaml" 2>$null
    
    # Correction des chemins
    $path = switch ($service) {
        "billing-service" { "k8s/services/billing/deployment.yaml" }
        "usage-collector-service" { "k8s/services/usage-collector/deployment.yaml" }
        "optimizer-service" { "k8s/services/optimizer/deployment.yaml" }
        "peak-detector-service" { "k8s/services/peak-detector/deployment.yaml" }
        "device-simulator-service" { "k8s/services/device-simulator/deployment.yaml" }
    }
    
    kubectl apply -f $path
}

Write-Host "✅ Toutes les configurations appliquées" -ForegroundColor Green
Write-Host ""

# 3. Supprimer les pods en erreur
Write-Host "3. Nettoyage des pods en erreur..." -ForegroundColor Yellow

# Supprimer les pods en CrashLoopBackOff
$crashLoopPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$crashLoopPods = $crashLoopPods.items | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
}

foreach ($pod in $crashLoopPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
}

# Supprimer les pods en Pending
$pendingPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$pendingPods = $pendingPods.items | Where-Object { $_.status.phase -eq "Pending" }

foreach ($pod in $pendingPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
}

Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
Write-Host ""

# 4. Redémarrer RabbitMQ pour appliquer la nouvelle configuration
Write-Host "4. Redémarrage de RabbitMQ..." -ForegroundColor Yellow
$rabbitmqPod = kubectl get pods -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($rabbitmqPod) {
    kubectl delete pod -n $namespace $rabbitmqPod --grace-period=0 --force 2>$null
    Write-Host "✅ RabbitMQ redémarré" -ForegroundColor Green
} else {
    Write-Host "⚠️  Pod RabbitMQ introuvable" -ForegroundColor Yellow
}
Write-Host ""

# 5. Redémarrer tous les services Spring Boot
Write-Host "5. Redémarrage des services Spring Boot..." -ForegroundColor Yellow

foreach ($service in $services) {
    Write-Host "   Redémarrage de $service..." -ForegroundColor Cyan
    
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
    Start-Sleep -Seconds 2
}

Write-Host "✅ Tous les services redémarrés" -ForegroundColor Green
Write-Host ""

# 6. Afficher l'état final
Write-Host "6. ÉTAT ACTUEL DES PODS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTIONS APPLIQUÉES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Améliorations appliquées:" -ForegroundColor Yellow
Write-Host "  ✅ RabbitMQ: Timeouts augmentés (15s), mémoire limitée à 60%" -ForegroundColor White
Write-Host "  ✅ Services Spring Boot: Startup probes améliorées (30s initial, 10s timeout)" -ForegroundColor White
Write-Host "  ✅ Services Spring Boot: Readiness probes améliorées (60s initial, 10s timeout)" -ForegroundColor White
Write-Host ""
Write-Host "Surveillez l'état des pods avec:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""
Write-Host "Les pods devraient devenir prêts dans les 2-5 prochaines minutes." -ForegroundColor Green
Write-Host ""


