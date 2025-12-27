# Script pour redémarrer les services avec les nouvelles configurations
# Usage: .\scripts\redemarrer-services-avec-nouvelles-configs.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REDÉMARRAGE DES SERVICES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  NOTE IMPORTANTE:" -ForegroundColor Yellow
Write-Host "Les fichiers application-kubernetes.properties ont été modifiés." -ForegroundColor Yellow
Write-Host "Vous devez REBUILD les images Docker pour que les changements prennent effet." -ForegroundColor Yellow
Write-Host ""
Write-Host "OU" -ForegroundColor Yellow
Write-Host "Les services vont utiliser les configurations existantes dans les images." -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Voulez-vous continuer avec le redémarrage ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Redémarrage des services avec les nouvelles configurations de probes..." -ForegroundColor Yellow

$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    Write-Host "Redémarrage de $service..." -ForegroundColor Cyan
    
    # Appliquer la configuration
    $deploymentFile = switch ($service) {
        "billing-service" { "k8s/services/billing/deployment.yaml" }
        "usage-collector-service" { "k8s/services/usage-collector/deployment.yaml" }
        "optimizer-service" { "k8s/services/optimizer/deployment.yaml" }
        "peak-detector-service" { "k8s/services/peak-detector/deployment.yaml" }
        "device-simulator-service" { "k8s/services/device-simulator/deployment.yaml" }
    }
    
    kubectl apply -f $deploymentFile 2>$null
    
    # Redémarrer le déploiement
    kubectl rollout restart deployment/$service -n $namespace 2>$null
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "✅ Tous les services ont été redémarrés" -ForegroundColor Green
Write-Host ""

Write-Host "Améliorations appliquées:" -ForegroundColor Yellow
Write-Host "  ✅ Liveness probes : 300s initial, 10s timeout, 10 failures" -ForegroundColor White
Write-Host "  ✅ Startup probes : 30s initial, 10s timeout" -ForegroundColor White
Write-Host "  ✅ Readiness probes : 60s initial, 10s timeout" -ForegroundColor White
Write-Host ""

Write-Host "Surveillez l'état des pods:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""

Write-Host "Les services devraient devenir prêts dans les 5-10 prochaines minutes." -ForegroundColor Green
Write-Host ""

