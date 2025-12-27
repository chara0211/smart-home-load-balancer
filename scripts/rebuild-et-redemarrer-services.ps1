# Script pour rebuild et redémarrer les services
# Usage: .\scripts\rebuild-et-redemarrer-services.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REBUILD ET REDÉMARRAGE DES SERVICES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Ce script va :" -ForegroundColor Yellow
Write-Host "  1. Rebuild les images Docker de tous les services" -ForegroundColor White
Write-Host "  2. Push les images vers Docker Hub" -ForegroundColor White
Write-Host "  3. Redémarrer les services dans Kubernetes" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Voulez-vous continuer ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

$services = @(
    @{Name="billing-service"; Port=8086; Path="billing-service"},
    @{Name="usage-collector-service"; Port=8083; Path="usage-collector-service"},
    @{Name="optimizer-service"; Port=8085; Path="optimizer-service"},
    @{Name="peak-detector-service"; Port=8084; Path="peak-detector-service"},
    @{Name="device-simulator-service"; Port=8082; Path="device-simulator-service"}
)

$namespace = "smarthome"

foreach ($service in $services) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Traitement de $($service.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # 1. Build
    Write-Host "1. Build de l'image..." -ForegroundColor Yellow
    Push-Location $service.Path
    docker build -t "salmaidoufkir/$($service.Name):latest" .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors du build de $($service.Name)" -ForegroundColor Red
        Pop-Location
        continue
    }
    Write-Host "✅ Build réussi" -ForegroundColor Green
    Pop-Location
    
    # 2. Push
    Write-Host "2. Push de l'image..." -ForegroundColor Yellow
    docker push "salmaidoufkir/$($service.Name):latest"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Erreur lors du push de $($service.Name)" -ForegroundColor Yellow
        Write-Host "   Continuez quand même..." -ForegroundColor Gray
    } else {
        Write-Host "✅ Push réussi" -ForegroundColor Green
    }
    
    # 3. Redémarrer le service
    Write-Host "3. Redémarrage du service dans Kubernetes..." -ForegroundColor Yellow
    kubectl rollout restart "deployment/$($service.Name)" -n $namespace
    Write-Host "✅ Service redémarré" -ForegroundColor Green
    
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REBUILD TERMINÉ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Surveillez l'état des pods :" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""
Write-Host "Les services devraient devenir prêts dans les 5-10 prochaines minutes." -ForegroundColor Green
Write-Host ""

