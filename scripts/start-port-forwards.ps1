# Script pour démarrer tous les port-forwards en arrière-plan
# Les services seront accessibles sur localhost

Write-Host "=== Démarrage des Port-Forwards ===" -ForegroundColor Green
Write-Host ""

# Vérifier que les services existent
Write-Host "Vérification des services..." -ForegroundColor Yellow
$services = @(
    "usage-collector-service",
    "peak-detector-service",
    "optimizer-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    $exists = kubectl get service $service -n smarthome 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Service $service n'existe pas" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Tous les services existent" -ForegroundColor Green
Write-Host ""

# Démarrer les port-forwards dans des fenêtres séparées
Write-Host "Démarrage des port-forwards..." -ForegroundColor Yellow

# Usage Collector Service (8083)
Write-Host "  → Usage Collector Service (port 8083)" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Port-forward: usage-collector-service 8083:8083' -ForegroundColor Green; kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome"
Start-Sleep -Seconds 2

# Peak Detector Service (8084)
Write-Host "  → Peak Detector Service (port 8084)" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Port-forward: peak-detector-service 8084:8084' -ForegroundColor Green; kubectl port-forward service/peak-detector-service 8084:8084 -n smarthome"
Start-Sleep -Seconds 2

# Optimizer Service (8085)
Write-Host "  → Optimizer Service (port 8085)" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Port-forward: optimizer-service 8085:8085' -ForegroundColor Green; kubectl port-forward service/optimizer-service 8085:8085 -n smarthome"
Start-Sleep -Seconds 2

# Device Simulator Service (8082)
Write-Host "  → Device Simulator Service (port 8082)" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Port-forward: device-simulator-service 8082:8082' -ForegroundColor Green; kubectl port-forward service/device-simulator-service 8082:8082 -n smarthome"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "✅ Tous les port-forwards sont démarrés !" -ForegroundColor Green
Write-Host ""
Write-Host "Services accessibles sur :" -ForegroundColor Yellow
Write-Host "  - Usage Collector  : http://localhost:8083" -ForegroundColor Cyan
Write-Host "  - Peak Detector    : http://localhost:8084" -ForegroundColor Cyan
Write-Host "  - Optimizer        : http://localhost:8085" -ForegroundColor Cyan
Write-Host "  - Device Simulator : http://localhost:8082" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vous pouvez maintenant tester avec Postman !" -ForegroundColor Green
Write-Host ""
Write-Host "Note : Fermez les fenêtres PowerShell pour arrêter les port-forwards" -ForegroundColor Gray

