# Script pour corriger rapidement les erreurs 401
# Usage: .\scripts\corriger-401-rapide.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTION RAPIDE - ERREURS 401" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Ce script va :" -ForegroundColor Yellow
Write-Host "  1. Corriger usage-collector-service (désactiver validation startupState)" -ForegroundColor White
Write-Host "  2. Désactiver temporairement l'authentification dans tous les services" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  ATTENTION : L'authentification sera désactivée (développement uniquement)" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Voulez-vous continuer ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "1. Correction de usage-collector-service..." -ForegroundColor Yellow
kubectl set env deployment/usage-collector-service -n $namespace MANAGEMENT_ENDPOINT_HEALTH_VALIDATE_GROUP_MEMBERSHIP=false
kubectl rollout restart deployment/usage-collector-service -n $namespace

Write-Host ""
Write-Host "2. Les SecurityConfig ont été modifiés pour désactiver l'authentification." -ForegroundColor Yellow
Write-Host "   Vous devez REBUILD les images Docker pour que les changements prennent effet." -ForegroundColor Yellow
Write-Host ""
Write-Host "   Pour rebuild rapidement :" -ForegroundColor Cyan
Write-Host "   .\scripts\rebuild-et-redemarrer-services.ps1" -ForegroundColor White
Write-Host ""

Write-Host "✅ Correction appliquée" -ForegroundColor Green
Write-Host ""
Write-Host "Surveillez les pods :" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""

