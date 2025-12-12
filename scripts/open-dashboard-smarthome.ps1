# Script pour ouvrir le dashboard Minikube directement sur le namespace smarthome

Write-Host "=== Ouverture du Dashboard Minikube (namespace: smarthome) ===" -ForegroundColor Green
Write-Host ""

# Vérifier que Minikube est en cours d'exécution
Write-Host "Vérification de Minikube..." -ForegroundColor Yellow
$minikubeStatus = minikube status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Minikube n'est pas en cours d'exécution" -ForegroundColor Red
    Write-Host "Lancez d'abord : minikube start" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Minikube est en cours d'exécution" -ForegroundColor Green
Write-Host ""

# Vérifier que le namespace smarthome existe
Write-Host "Vérification du namespace 'smarthome'..." -ForegroundColor Yellow
$namespaceExists = kubectl get namespace smarthome 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Le namespace 'smarthome' n'existe pas" -ForegroundColor Red
    Write-Host "Création du namespace..." -ForegroundColor Yellow
    kubectl create namespace smarthome
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Impossible de créer le namespace" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Namespace créé" -ForegroundColor Green
} else {
    Write-Host "✅ Namespace 'smarthome' existe" -ForegroundColor Green
}
Write-Host ""

# Démarrer le dashboard en arrière-plan
Write-Host "Démarrage du dashboard..." -ForegroundColor Yellow
Start-Process -NoNewWindow -FilePath "minikube" -ArgumentList "dashboard" -ErrorAction SilentlyContinue

# Attendre un peu pour que le dashboard démarre
Start-Sleep -Seconds 3

# Obtenir l'URL du dashboard
Write-Host "Récupération de l'URL du dashboard..." -ForegroundColor Yellow
$dashboardOutput = minikube dashboard --url 2>&1

# Extraire l'URL
$dashboardUrl = $null
if ($dashboardOutput -match 'http://[^\s]+') {
    $dashboardUrl = $matches[0]
}

if ($dashboardUrl) {
    # Construire l'URL avec le namespace
    $namespaceUrl = "$dashboardUrl/#/workloads?namespace=smarthome"
    
    Write-Host ""
    Write-Host "✅ Dashboard démarré !" -ForegroundColor Green
    Write-Host ""
    Write-Host "URL du dashboard :" -ForegroundColor Cyan
    Write-Host "  $dashboardUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "URL directe (namespace smarthome) :" -ForegroundColor Cyan
    Write-Host "  $namespaceUrl" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ouverture dans le navigateur..." -ForegroundColor Yellow
    
    # Ouvrir dans le navigateur
    Start-Process $namespaceUrl
    
    Write-Host ""
    Write-Host "✅ Dashboard ouvert dans le navigateur sur le namespace 'smarthome'" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note : Si le dashboard ne s'ouvre pas automatiquement," -ForegroundColor Gray
    Write-Host "      copiez l'URL ci-dessus dans votre navigateur." -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "⚠️  Impossible d'obtenir l'URL automatiquement" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Le dashboard devrait s'être ouvert automatiquement." -ForegroundColor Yellow
    Write-Host "Dans le dashboard, sélectionnez le namespace 'smarthome' dans le menu déroulant." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ou exécutez manuellement :" -ForegroundColor Cyan
    Write-Host "  minikube dashboard --url" -ForegroundColor White
}

