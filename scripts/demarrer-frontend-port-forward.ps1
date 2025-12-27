# Script pour démarrer le port-forward du frontend
# Usage: .\scripts\demarrer-frontend-port-forward.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DÉMARRAGE PORT-FORWARD FRONTEND" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Vérification de l'état du frontend..." -ForegroundColor Yellow
$pod = kubectl get pods -n $namespace -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>$null
if (-not $pod) {
    Write-Host "❌ Aucun pod frontend trouvé" -ForegroundColor Red
    exit 1
}

$ready = kubectl get pods -n $namespace -l app=frontend -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
if ($ready -ne "true") {
    Write-Host "⚠️  Le pod frontend n'est pas prêt" -ForegroundColor Yellow
    Write-Host "   Attendez quelques secondes et réessayez" -ForegroundColor Gray
}

Write-Host "✅ Pod frontend trouvé : $pod" -ForegroundColor Green
Write-Host ""

Write-Host "Démarrage du port-forward..." -ForegroundColor Yellow
Write-Host "   Frontend sera accessible sur : http://localhost:3000" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  Appuyez sur Ctrl+C pour arrêter le port-forward" -ForegroundColor Yellow
Write-Host ""

# Démarrer le port-forward
kubectl port-forward -n $namespace svc/frontend-service-nodeport 3000:3000

