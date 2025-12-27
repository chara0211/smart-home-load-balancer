# Script pour tester avec NodePort
# Usage: .\scripts\test-avec-nodeport.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST AVEC NODEPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Obtenir l'IP de Minikube
$minikubeIp = minikube ip
$frontendUrl = "http://$minikubeIp:30000"
$keycloakUrl = "http://$minikubeIp:30080"

Write-Host "URLs des services :" -ForegroundColor Yellow
Write-Host "  Frontend: $frontendUrl" -ForegroundColor Green
Write-Host "  Keycloak: $keycloakUrl" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ÉTAPES DE CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Accéder à Keycloak :" -ForegroundColor Yellow
Write-Host "   $keycloakUrl" -ForegroundColor White
Write-Host "   Ou : minikube service keycloak-service -n $namespace" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Configurer le client 'frontend-client' :" -ForegroundColor Yellow
Write-Host "   - Valid redirect URIs: $frontendUrl/*" -ForegroundColor White
Write-Host "   - Web origins: $frontendUrl" -ForegroundColor White
Write-Host ""

Write-Host "3. Créer un utilisateur de test :" -ForegroundColor Yellow
Write-Host "   - Username: testuser" -ForegroundColor White
Write-Host "   - Password: testpass" -ForegroundColor White
Write-Host ""

Write-Host "4. Tester le frontend :" -ForegroundColor Yellow
Write-Host "   $frontendUrl" -ForegroundColor White
Write-Host "   Ou : minikube service frontend-service-nodeport -n $namespace" -ForegroundColor Gray
Write-Host ""

$open = Read-Host "Voulez-vous ouvrir les URLs dans le navigateur ? (O/N)"
if ($open -eq "O" -or $open -eq "o") {
    Start-Process $keycloakUrl
    Start-Sleep -Seconds 2
    Start-Process $frontendUrl
    Write-Host ""
    Write-Host "✅ URLs ouvertes dans le navigateur" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST RAPIDE AVEC POWERSHELL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour tester l'authentification avec PowerShell :" -ForegroundColor Yellow
Write-Host ""
Write-Host '$response = Invoke-RestMethod -Uri "' -NoNewline -ForegroundColor Gray
Write-Host "$keycloakUrl/realms/smarthome/protocol/openid-connect/token" -NoNewline -ForegroundColor White
Write-Host '" -Method Post -Body @{grant_type="password";client_id="frontend-client";username="testuser";password="testpass"} -ContentType "application/x-www-form-urlencoded"' -ForegroundColor Gray
Write-Host '$token = $response.access_token' -ForegroundColor Gray
Write-Host 'Write-Host "Token: $($token.Substring(0, 50))..."' -ForegroundColor Gray
Write-Host ""

