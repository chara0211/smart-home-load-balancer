# Script pour migrer Minikube vers le driver Hyper-V
# Usage: .\scripts\migrate-to-hyperv.ps1
# Nécessite les droits administrateur

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Migration Minikube vers Hyper-V" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier les droits administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERREUR: Ce script nécessite les droits administrateur !" -ForegroundColor Red
    Write-Host "Relancez PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    exit 1
}

# Vérifier que Hyper-V est disponible
Write-Host "Vérification de Hyper-V..." -ForegroundColor Yellow
$hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue

if (-not $hypervFeature) {
    Write-Host "ERREUR: Hyper-V n'est pas disponible sur ce système !" -ForegroundColor Red
    Write-Host "Hyper-V nécessite Windows 10/11 Pro, Enterprise ou Education." -ForegroundColor Yellow
    exit 1
}

if ($hypervFeature.State -ne "Enabled") {
    Write-Host "Hyper-V n'est pas activé. Voulez-vous l'activer maintenant ? (O/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "O" -or $response -eq "o") {
        Write-Host "Activation de Hyper-V..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
        Write-Host "Hyper-V activé. Un redémarrage sera nécessaire." -ForegroundColor Green
        Write-Host "Redémarrez votre ordinateur, puis relancez ce script." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "Migration annulée." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Hyper-V est disponible ✓" -ForegroundColor Green
Write-Host ""

# Vérifier l'état actuel de Minikube
Write-Host "Vérification de l'état actuel de Minikube..." -ForegroundColor Yellow
$minikubeStatus = minikube status 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Minikube est actuellement en cours d'exécution." -ForegroundColor Yellow
    Write-Host "Voulez-vous continuer la migration ? Cela va arrêter et supprimer le cluster actuel. (O/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne "O" -and $response -ne "o") {
        Write-Host "Migration annulée." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Arrêt de Minikube..." -ForegroundColor Yellow
    minikube stop
    Write-Host "Suppression du cluster actuel..." -ForegroundColor Yellow
    minikube delete
} else {
    Write-Host "Minikube n'est pas en cours d'exécution." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Création d'un nouveau cluster Minikube avec le driver Hyper-V..." -ForegroundColor Yellow
Write-Host "Cela peut prendre quelques minutes..." -ForegroundColor Gray

# Créer le nouveau cluster avec Hyper-V
minikube start --driver=hyperv

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: Échec de la création du cluster avec Hyper-V !" -ForegroundColor Red
    Write-Host "Vérifiez que Hyper-V est correctement configuré." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ Migration terminée avec succès !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Afficher les informations
$ip = minikube ip
Write-Host "IP de Minikube: $ip" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vérification du driver:" -ForegroundColor Yellow
minikube profile list
Write-Host ""

Write-Host "📝 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "1. Redéployez tous vos services (voir GUIDE-REDEPLOIEMENT-COMPLET.md)" -ForegroundColor White
Write-Host "2. Une fois déployés, accédez aux services via:" -ForegroundColor White
Write-Host "   - Frontend: http://$ip`:30000" -ForegroundColor Gray
Write-Host "   - Usage Collector: http://$ip`:30083" -ForegroundColor Gray
Write-Host "   - Device Simulator: http://$ip`:30082" -ForegroundColor Gray
Write-Host "   - Peak Detector: http://$ip`:30084" -ForegroundColor Gray
Write-Host "   - Optimizer: http://$ip`:30085" -ForegroundColor Gray
Write-Host "   - Billing: http://$ip`:30086" -ForegroundColor Gray
Write-Host ""
Write-Host "Aucun processus en arrière-plan nécessaire ! 🎉" -ForegroundColor Green

