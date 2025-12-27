# Script pour rebuild et push l'image frontend
# Usage: .\scripts\rebuild-frontend.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REBUILD ET PUSH FRONTEND" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Ce script va :" -ForegroundColor Yellow
Write-Host "  1. Build l'image Docker du frontend" -ForegroundColor White
Write-Host "  2. Push l'image vers Docker Hub" -ForegroundColor White
Write-Host "  3. Redémarrer le déploiement dans Kubernetes" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Voulez-vous continuer ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "1. Build de l'image..." -ForegroundColor Yellow
Push-Location frontend
docker build -t salmaidoufkir/frontend:latest .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build" -ForegroundColor Red
    Pop-Location
    exit 1
}
Write-Host "✅ Build réussi" -ForegroundColor Green
Pop-Location

Write-Host ""
Write-Host "2. Push de l'image..." -ForegroundColor Yellow
docker push salmaidoufkir/frontend:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Erreur lors du push" -ForegroundColor Yellow
    Write-Host "   Vérifiez que vous êtes connecté à Docker Hub" -ForegroundColor Gray
} else {
    Write-Host "✅ Push réussi" -ForegroundColor Green
}

Write-Host ""
Write-Host "3. Redémarrage du déploiement..." -ForegroundColor Yellow
kubectl rollout restart deployment/frontend -n smarthome
Write-Host "✅ Déploiement redémarré" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TERMINÉ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Surveillez le redéploiement :" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n smarthome -l app=frontend -w" -ForegroundColor White
Write-Host ""
Write-Host "Le nouveau pod devrait être prêt dans 1-2 minutes." -ForegroundColor Green
Write-Host ""

