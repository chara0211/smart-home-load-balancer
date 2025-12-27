# Script pour tester l'authentification
# Usage: .\scripts\test-authentification.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST DE L'AUTHENTIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier l'état des services
Write-Host "1. Vérification de l'état des services..." -ForegroundColor Yellow
kubectl get pods -n $namespace | Select-String "keycloak|frontend|billing|usage|device|peak|optimizer"

Write-Host ""
Write-Host "2. Port-forward pour accéder aux services..." -ForegroundColor Yellow
Write-Host ""

# 2. Port-forward Keycloak
Write-Host "   Keycloak sera accessible sur http://localhost:8080" -ForegroundColor Green
Write-Host "   Frontend sera accessible sur http://localhost:3000" -ForegroundColor Green
Write-Host ""

Write-Host "3. Pour tester Keycloak directement :" -ForegroundColor Yellow
Write-Host "   kubectl port-forward -n $namespace svc/keycloak-service 8080:8080" -ForegroundColor White
Write-Host ""

Write-Host "4. Pour tester le Frontend :" -ForegroundColor Yellow
Write-Host "   kubectl port-forward -n $namespace svc/frontend-service 3000:3000" -ForegroundColor White
Write-Host ""

Write-Host "5. Pour tester un service backend (ex: billing) :" -ForegroundColor Yellow
Write-Host "   kubectl port-forward -n $namespace <billing-pod-name> 8086:8086" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ÉTAPES DE TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "A. Configuration Keycloak :" -ForegroundColor Yellow
Write-Host "   1. Accéder à http://localhost:8080" -ForegroundColor White
Write-Host "   2. Se connecter avec les credentials admin" -ForegroundColor White
Write-Host "   3. Créer un realm 'smarthome' (ou utiliser celui existant)" -ForegroundColor White
Write-Host "   4. Créer un client 'frontend-client' (public)" -ForegroundColor White
Write-Host "   5. Créer un utilisateur de test" -ForegroundColor White
Write-Host ""

Write-Host "B. Test de l'authentification :" -ForegroundColor Yellow
Write-Host "   1. Ouvrir http://localhost:3000" -ForegroundColor White
Write-Host "   2. Se connecter avec les credentials Keycloak" -ForegroundColor White
Write-Host "   3. Vérifier que le dashboard s'affiche" -ForegroundColor White
Write-Host "   4. Vérifier que les erreurs 401 ont disparu" -ForegroundColor White
Write-Host ""

Write-Host "C. Test manuel avec curl :" -ForegroundColor Yellow
Write-Host "   # Obtenir un token" -ForegroundColor White
Write-Host "   `$token = (Invoke-RestMethod -Uri 'http://localhost:8080/realms/smarthome/protocol/openid-connect/token' -Method Post -Body @{grant_type='password';client_id='frontend-client';username='testuser';password='testpass'} -ContentType 'application/x-www-form-urlencoded').access_token" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Tester un endpoint avec le token" -ForegroundColor White
Write-Host "   Invoke-RestMethod -Uri 'http://localhost:8086/billing/savings' -Headers @{Authorization='Bearer ' + `$token}" -ForegroundColor Gray
Write-Host ""

