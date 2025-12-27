# Script pour ouvrir le frontend via NodePort
# Usage: .\scripts\ouvrir-frontend-nodeport.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OUVERTURE DU FRONTEND VIA NODEPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Obtenir l'IP de Minikube
$minikubeIp = minikube ip
if (-not $minikubeIp) {
    Write-Host "❌ Erreur : Minikube n'est pas en cours d'exécution" -ForegroundColor Red
    exit 1
}

# Obtenir le NodePort
$nodePort = kubectl get svc -n $namespace frontend-service-nodeport -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
if (-not $nodePort) {
    Write-Host "❌ Erreur : Service frontend-service-nodeport introuvable" -ForegroundColor Red
    exit 1
}

$url = "http://$minikubeIp:$nodePort"

Write-Host "URL du frontend : $url" -ForegroundColor Green
Write-Host ""
Write-Host "Ouverture dans le navigateur..." -ForegroundColor Yellow

Start-Process $url

Write-Host ""
Write-Host "✅ Frontend ouvert dans le navigateur" -ForegroundColor Green
Write-Host ""
Write-Host "Note : Utilisez cette URL pour configurer Keycloak :" -ForegroundColor Yellow
Write-Host "  - Valid redirect URIs: $url/*" -ForegroundColor White
Write-Host "  - Web origins: $url" -ForegroundColor White
Write-Host ""

