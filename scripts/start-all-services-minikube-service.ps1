# Script pour ouvrir tous les services avec minikube service
# Usage: .\scripts\start-all-services-minikube-service.ps1

$NAMESPACE = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Ouverture de Tous les Services" -ForegroundColor Cyan
Write-Host "  Smart Home Load Balancer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Liste des services NodePort
$services = @(
    @{Name = "frontend-service-nodeport"; DisplayName = "Frontend"},
    @{Name = "usage-collector-service-nodeport"; DisplayName = "Usage Collector Service"},
    @{Name = "device-simulator-service-nodeport"; DisplayName = "Device Simulator Service"},
    @{Name = "peak-detector-service-nodeport"; DisplayName = "Peak Detector Service"},
    @{Name = "optimizer-service-nodeport"; DisplayName = "Optimizer Service"},
    @{Name = "billing-service-nodeport"; DisplayName = "Billing Service"}
)

# Vérifier que minikube est disponible
try {
    $null = minikube status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERREUR: Minikube n'est pas en cours d'exécution !" -ForegroundColor Red
        Write-Host "Lancez d'abord: minikube start" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "ERREUR: minikube n'est pas disponible !" -ForegroundColor Red
    exit 1
}

Write-Host "Ouverture de tous les services dans le navigateur..." -ForegroundColor Yellow
Write-Host ""

# Ouvrir chaque service dans le navigateur
foreach ($service in $services) {
    Write-Host "Ouverture de $($service.DisplayName)..." -ForegroundColor Gray
    
    # Lancer minikube service dans une nouvelle fenêtre PowerShell
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "minikube service $($service.Name) -n $NAMESPACE"
    
    # Attendre un peu entre chaque ouverture
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ Tous les services sont en cours d'ouverture !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Les fenêtres PowerShell vont s'ouvrir et lancer minikube service pour chaque service." -ForegroundColor Yellow
Write-Host "   Votre navigateur s'ouvrira automatiquement pour chaque service." -ForegroundColor Yellow
Write-Host ""

