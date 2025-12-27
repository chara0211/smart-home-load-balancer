# Script pour libérer de la mémoire en réduisant les replicas
# Usage: .\scripts\liberer-memoire-cluster.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LIBÉRATION DE MÉMOIRE DANS LE CLUSTER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "smarthome"

Write-Host "Réduction des replicas des services pour libérer de la mémoire..." -ForegroundColor Yellow
Write-Host ""

# Services à réduire à 1 replica
$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    Write-Host "Réduction de $service à 1 replica..." -ForegroundColor Cyan
    kubectl scale deployment/$service -n $namespace --replicas=1 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $service réduit à 1 replica" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Erreur lors de la réduction de $service" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Suppression des pods en Pending..." -ForegroundColor Yellow

# Supprimer tous les pods en Pending
$pendingPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$pendingPods = $pendingPods.items | Where-Object { $_.status.phase -eq "Pending" }

foreach ($pod in $pendingPods) {
    $podName = $pod.metadata.name
    Write-Host "  Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
}

Write-Host ""
Write-Host "✅ Mémoire libérée" -ForegroundColor Green
Write-Host ""
Write-Host "État actuel des pods:" -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""
Write-Host "RabbitMQ devrait maintenant pouvoir démarrer." -ForegroundColor Green
Write-Host "Surveillez avec: kubectl get pods -n $namespace -l app=rabbitmq -w" -ForegroundColor White
Write-Host ""


