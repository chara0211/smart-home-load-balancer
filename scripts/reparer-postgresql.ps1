# Script pour réparer PostgreSQL
# Usage: .\scripts\reparer-postgresql.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RÉPARATION DE POSTGRESQL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  ATTENTION : Cette opération va supprimer toutes les données PostgreSQL !" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Voulez-vous continuer ? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Annulé." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "1. Suppression du déploiement PostgreSQL..." -ForegroundColor Yellow
kubectl delete deployment postgres -n $namespace --ignore-not-found=true
Write-Host "✅ Déploiement supprimé" -ForegroundColor Green
Write-Host ""

Write-Host "2. Suppression du PVC PostgreSQL..." -ForegroundColor Yellow
kubectl delete pvc postgres-pvc -n $namespace --ignore-not-found=true
Write-Host "✅ PVC supprimé" -ForegroundColor Green
Write-Host ""

Write-Host "3. Attente de 10 secondes..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Write-Host ""

Write-Host "4. Recréation de PostgreSQL..." -ForegroundColor Yellow
kubectl apply -f k8s/databases/postgres-deployment.yaml
Write-Host "✅ PostgreSQL recréé" -ForegroundColor Green
Write-Host ""

Write-Host "5. Attente que PostgreSQL soit prêt (timeout: 5 minutes)..." -ForegroundColor Yellow
$timeout = 300
$elapsed = 0
$interval = 10

while ($elapsed -lt $timeout) {
    $postgresPod = kubectl get pods -n $namespace -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($postgresPod) {
        $podStatus = kubectl get pod -n $namespace $postgresPod -o jsonpath='{.status.phase}' 2>$null
        $containerReady = kubectl get pod -n $namespace $postgresPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
        
        if ($podStatus -eq "Running" -and $containerReady -eq "true") {
            Write-Host "✅ PostgreSQL est prêt !" -ForegroundColor Green
            break
        }
    }
    
    Write-Host "   En attente... ($elapsed/$timeout secondes) - Status: $podStatus" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if ($elapsed -ge $timeout) {
    Write-Host "⚠️  Timeout: PostgreSQL n'est pas prêt après 5 minutes" -ForegroundColor Yellow
    Write-Host "   Vérifiez les logs: kubectl logs -n $namespace -l app=postgres --tail=50" -ForegroundColor White
}

Write-Host ""
Write-Host "6. État final..." -ForegroundColor Yellow
kubectl get pods -n $namespace -l app=postgres
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RÉPARATION TERMINÉE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Une fois PostgreSQL prêt, les autres services devraient se connecter automatiquement." -ForegroundColor Green
Write-Host ""

