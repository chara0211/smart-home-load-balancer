# Script pour lancer tous les port-forwards des services en arrière-plan
# Usage: .\scripts\start-all-services-port-forward.ps1

$NAMESPACE = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Démarrage des Port-Forwards" -ForegroundColor Cyan
Write-Host "  Smart Home Load Balancer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Liste des services avec leurs ports
$services = @(
    @{Name = "frontend-service"; Port = 3000; DisplayName = "Frontend"},
    @{Name = "usage-collector-service"; Port = 8083; DisplayName = "Usage Collector Service"},
    @{Name = "device-simulator-service"; Port = 8082; DisplayName = "Device Simulator Service"},
    @{Name = "peak-detector-service"; Port = 8084; DisplayName = "Peak Detector Service"},
    @{Name = "optimizer-service"; Port = 8085; DisplayName = "Optimizer Service"},
    @{Name = "billing-service"; Port = 8086; DisplayName = "Billing Service"}
)

# Fonction pour lancer un port-forward en arrière-plan
function Start-PortForward {
    param(
        [string]$ServiceName,
        [int]$Port,
        [string]$DisplayName
    )
    
    Write-Host "Démarrage du port-forward pour $DisplayName..." -ForegroundColor Gray
    
    # Créer une fenêtre PowerShell séparée pour chaque port-forward
    $scriptBlock = {
        param($ServiceName, $Port, $Namespace, $DisplayName)
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  $DisplayName" -ForegroundColor Green
        Write-Host "  Port: $Port" -ForegroundColor Green
        Write-Host "  URL: http://localhost:$Port" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Port-forward actif. Appuyez sur Ctrl+C pour arrêter." -ForegroundColor Yellow
        Write-Host ""
        
        kubectl port-forward service/$ServiceName $Port`:$Port -n $Namespace
    }
    
    # Lancer dans une nouvelle fenêtre PowerShell
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { $($scriptBlock.ToString()) } -ServiceName '$ServiceName' -Port $Port -Namespace '$NAMESPACE' -DisplayName '$DisplayName'"
    
    # Attendre un peu pour que le port-forward démarre
    Start-Sleep -Seconds 2
}

# Vérifier que kubectl est disponible
try {
    $null = kubectl version --client 2>&1
} catch {
    Write-Host "ERREUR: kubectl n'est pas disponible !" -ForegroundColor Red
    Write-Host "Veuillez installer kubectl ou vérifier votre configuration." -ForegroundColor Yellow
    exit 1
}

# Vérifier que le namespace existe
$namespaceExists = kubectl get namespace $NAMESPACE 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: Le namespace '$NAMESPACE' n'existe pas !" -ForegroundColor Red
    exit 1
}

Write-Host "Démarrage des port-forwards pour tous les services..." -ForegroundColor Yellow
Write-Host ""

# Lancer tous les port-forwards
foreach ($service in $services) {
    Start-PortForward -ServiceName $service.Name -Port $service.Port -DisplayName $service.DisplayName
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ Tous les port-forwards sont lancés !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 URLs d'accès aux services :" -ForegroundColor Cyan
Write-Host ""
foreach ($service in $services) {
    Write-Host "  $($service.DisplayName):" -ForegroundColor White
    Write-Host "    http://localhost:$($service.Port)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "💡 Astuce: Les fenêtres PowerShell ouvertes contiennent les port-forwards." -ForegroundColor Yellow
Write-Host "   Fermez-les pour arrêter les port-forwards." -ForegroundColor Yellow
Write-Host ""

