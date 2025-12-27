# Script pour désactiver les services non essentiels
# Usage: .\scripts\desactiver-services-non-essentiels.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DÉSACTIVATION DES SERVICES NON ESSENTIELS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Services qui seront désactivés :" -ForegroundColor Yellow
Write-Host "  - peak-detector-service" -ForegroundColor White
Write-Host "  - optimizer-service" -ForegroundColor White
Write-Host "  - device-simulator-service" -ForegroundColor White
Write-Host ""
Write-Host "Services qui resteront actifs :" -ForegroundColor Green
Write-Host "  - postgres" -ForegroundColor White
Write-Host "  - rabbitmq" -ForegroundColor White
Write-Host "  - usage-collector-service" -ForegroundColor White
Write-Host "  - billing-service" -ForegroundColor White
Write-Host "  - frontend" -ForegroundColor White
Write-Host "  - keycloak" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Voulez-vous continuer ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Désactivation des services..." -ForegroundColor Yellow

$servicesToDisable = @(
    "peak-detector-service",
    "optimizer-service",
    "device-simulator-service"
)

foreach ($service in $servicesToDisable) {
    Write-Host "  Désactivation de $service..." -ForegroundColor Cyan
    kubectl scale deployment/$service -n $namespace --replicas=0 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✅ $service désactivé" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️  Erreur lors de la désactivation de $service" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Attente de 30 secondes pour que les pods se terminent..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host ""

Write-Host "État actuel des pods..." -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DÉSACTIVATION TERMINÉE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Les services non essentiels ont été désactivés." -ForegroundColor Green
Write-Host "Cela devrait libérer de la mémoire et permettre aux services essentiels de démarrer." -ForegroundColor Green
Write-Host ""
Write-Host "Pour réactiver les services plus tard :" -ForegroundColor Yellow
Write-Host "  kubectl scale deployment/peak-detector-service -n $namespace --replicas=1" -ForegroundColor White
Write-Host "  kubectl scale deployment/optimizer-service -n $namespace --replicas=1" -ForegroundColor White
Write-Host "  kubectl scale deployment/device-simulator-service -n $namespace --replicas=1" -ForegroundColor White
Write-Host ""

