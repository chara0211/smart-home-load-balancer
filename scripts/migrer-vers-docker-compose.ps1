# Script pour migrer vers Docker Compose
# Usage: .\scripts\migrer-vers-docker-compose.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION VERS DOCKER COMPOSE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Ce script va :" -ForegroundColor Yellow
Write-Host "  1. Arrêter Minikube" -ForegroundColor White
Write-Host "  2. Vérifier que Docker est en cours d'exécution" -ForegroundColor White
Write-Host "  3. Démarrer les services avec Docker Compose" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Voulez-vous continuer ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "1. Arrêt de Minikube..." -ForegroundColor Yellow
minikube stop
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Minikube arrêté" -ForegroundColor Green
} else {
    Write-Host "⚠️  Minikube n'était peut-être pas démarré" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "2. Vérification de Docker..." -ForegroundColor Yellow
docker ps 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker est en cours d'exécution" -ForegroundColor Green
} else {
    Write-Host "❌ Docker n'est pas en cours d'exécution" -ForegroundColor Red
    Write-Host "   Veuillez démarrer Docker Desktop et réessayer" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

Write-Host "3. Démarrage avec Docker Compose..." -ForegroundColor Yellow
docker-compose up -d
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Services démarrés avec Docker Compose" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du démarrage" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "4. Vérification de l'état..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
docker-compose ps
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION TERMINÉE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commandes utiles :" -ForegroundColor Yellow
Write-Host "  docker-compose ps          - Voir l'état des services" -ForegroundColor White
Write-Host "  docker-compose logs -f     - Voir les logs en temps réel" -ForegroundColor White
Write-Host "  docker-compose down        - Arrêter les services" -ForegroundColor White
Write-Host "  docker-compose restart     - Redémarrer les services" -ForegroundColor White
Write-Host ""

