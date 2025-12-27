# Script pour démarrer les port-forwards et tester
# Usage: .\scripts\demarrer-tests.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DÉMARRAGE DES TESTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que les services sont prêts
Write-Host "Vérification de l'état des services..." -ForegroundColor Yellow
$keycloakReady = kubectl get pods -n $namespace -l app=keycloak -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
$frontendReady = kubectl get pods -n $namespace -l app=frontend -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null

if ($keycloakReady -ne "true") {
    Write-Host "❌ Keycloak n'est pas prêt" -ForegroundColor Red
    exit 1
}

if ($frontendReady -ne "true") {
    Write-Host "❌ Frontend n'est pas prêt" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Keycloak est prêt" -ForegroundColor Green
Write-Host "✅ Frontend est prêt" -ForegroundColor Green
Write-Host ""

# Démarrer les port-forwards
Write-Host "Démarrage des port-forwards..." -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Keycloak sur http://localhost:8080" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $namespace svc/keycloak-service 8080:8080" -WindowStyle Minimized

Start-Sleep -Seconds 2

Write-Host "2. Frontend sur http://localhost:3000" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n $namespace svc/frontend-service 3000:3000" -WindowStyle Minimized

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "✅ Port-forwards démarrés" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PROCHAINES ÉTAPES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Configurer Keycloak :" -ForegroundColor Yellow
Write-Host "   - Ouvrir http://localhost:8080" -ForegroundColor White
Write-Host "   - Se connecter avec les credentials admin" -ForegroundColor White
Write-Host "   - Créer le realm 'smarthome' (si nécessaire)" -ForegroundColor White
Write-Host "   - Créer le client 'frontend-client' (public)" -ForegroundColor White
Write-Host "   - Créer un utilisateur de test" -ForegroundColor White
Write-Host ""
Write-Host "2. Tester le Frontend :" -ForegroundColor Yellow
Write-Host "   - Ouvrir http://localhost:3000" -ForegroundColor White
Write-Host "   - Se connecter avec les credentials Keycloak" -ForegroundColor White
Write-Host "   - Vérifier que le dashboard s'affiche" -ForegroundColor White
Write-Host ""
Write-Host "3. Vérifier les erreurs :" -ForegroundColor Yellow
Write-Host "   - Ouvrir la console du navigateur (F12)" -ForegroundColor White
Write-Host "   - Vérifier qu'il n'y a plus d'erreurs 401" -ForegroundColor White
Write-Host ""
Write-Host "Pour arrêter les port-forwards, fermez les fenêtres PowerShell ouvertes." -ForegroundColor Gray
Write-Host ""

