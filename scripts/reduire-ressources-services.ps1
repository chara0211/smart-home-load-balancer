# Script pour réduire les ressources de tous les services
# Usage: .\scripts\reduire-ressources-services.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RÉDUCTION DES RESSOURCES DES SERVICES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Réduction des ressources pour libérer de la mémoire..." -ForegroundColor Yellow
Write-Host ""

# Réduire billing-service
Write-Host "Réduction de billing-service..." -ForegroundColor Cyan
kubectl set resources deployment billing-service -n $namespace --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m
Write-Host "  ✅ billing-service réduit" -ForegroundColor Green

# Réduire usage-collector-service
Write-Host "Réduction de usage-collector-service..." -ForegroundColor Cyan
kubectl set resources deployment usage-collector-service -n $namespace --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m
Write-Host "  ✅ usage-collector-service réduit" -ForegroundColor Green

# Réduire optimizer-service
Write-Host "Réduction de optimizer-service..." -ForegroundColor Cyan
kubectl set resources deployment optimizer-service -n $namespace --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m
Write-Host "  ✅ optimizer-service réduit" -ForegroundColor Green

# Réduire peak-detector-service
Write-Host "Réduction de peak-detector-service..." -ForegroundColor Cyan
kubectl set resources deployment peak-detector-service -n $namespace --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m
Write-Host "  ✅ peak-detector-service réduit" -ForegroundColor Green

# Réduire device-simulator-service
Write-Host "Réduction de device-simulator-service..." -ForegroundColor Cyan
kubectl set resources deployment device-simulator-service -n $namespace --requests=memory=128Mi,cpu=100m --limits=memory=256Mi,cpu=250m
Write-Host "  ✅ device-simulator-service réduit" -ForegroundColor Green

Write-Host ""
Write-Host "Suppression des pods pour qu'ils redémarrent avec les nouvelles ressources..." -ForegroundColor Yellow

$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    Write-Host "  Suppression des pods de $service..." -ForegroundColor Gray
    kubectl delete pod -n $namespace -l app=$service --grace-period=0 --force 2>$null
}

Write-Host ""
Write-Host "✅ Ressources réduites et pods redémarrés" -ForegroundColor Green
Write-Host ""
Write-Host "Attente de 30 secondes pour que la mémoire se libère..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host ""

Write-Host "Vérification de RabbitMQ..." -ForegroundColor Yellow
kubectl get pods -n $namespace -l app=rabbitmq
Write-Host ""

Write-Host "Surveillez RabbitMQ avec:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -l app=rabbitmq -w" -ForegroundColor White
Write-Host ""


