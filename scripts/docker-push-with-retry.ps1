# Script PowerShell pour pusher une image Docker avec retry automatique
# Usage: .\docker-push-with-retry.ps1 -ImageName "salmaidoufkir/usage-collector-service:latest"

param(
    [Parameter(Mandatory=$true)]
    [string]$ImageName,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxRetries = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$RetryDelaySeconds = 15
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push Docker avec Retry Automatique" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Image: $ImageName" -ForegroundColor Yellow
Write-Host "Tentatives max: $MaxRetries" -ForegroundColor Yellow
Write-Host "Délai entre tentatives: $RetryDelaySeconds secondes" -ForegroundColor Yellow
Write-Host ""

$retryCount = 0
$success = $false

# Vérifier que l'image existe localement
Write-Host "Vérification de l'image locale..." -ForegroundColor Cyan
$imageExists = docker images $ImageName --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern $ImageName

if (-not $imageExists) {
    Write-Host "ERREUR: L'image $ImageName n'existe pas localement !" -ForegroundColor Red
    Write-Host "Veuillez d'abord builder l'image avec: docker build -t $ImageName ." -ForegroundColor Yellow
    exit 1
}

Write-Host "Image trouvée localement ✓" -ForegroundColor Green
Write-Host ""

# Vérifier la connexion à Docker Hub
Write-Host "Test de connexion à Docker Hub..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://registry-1.docker.io/v2/" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "Connexion à Docker Hub OK ✓" -ForegroundColor Green
} catch {
    Write-Host "ATTENTION: Problème de connexion à Docker Hub" -ForegroundColor Yellow
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Le push peut échouer, mais on continue..." -ForegroundColor Yellow
}
Write-Host ""

# Boucle de retry
while (-not $success -and $retryCount -lt $MaxRetries) {
    $retryCount++
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Tentative $retryCount/$MaxRetries" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    try {
        # Exécuter le push
        $startTime = Get-Date
        docker push $ImageName 2>&1 | Tee-Object -Variable pushOutput
        
        # Vérifier le code de retour
        if ($LASTEXITCODE -eq 0) {
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            $success = $true
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "✓ PUSH RÉUSSI !" -ForegroundColor Green
            Write-Host "Durée: $([math]::Round($duration, 2)) secondes" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
        } else {
            throw "Docker push a échoué avec le code $LASTEXITCODE"
        }
    } catch {
        Write-Host ""
        Write-Host "✗ Échec de la tentative $retryCount" -ForegroundColor Red
        
        # Analyser le type d'erreur
        $errorMessage = $_.Exception.Message
        if ($pushOutput) {
            $errorMessage = $pushOutput -join "`n"
        }
        
        if ($errorMessage -match "broken pipe" -or $errorMessage -match "connection") {
            Write-Host "Type d'erreur: Problème de connexion réseau" -ForegroundColor Yellow
        } elseif ($errorMessage -match "unauthorized" -or $errorMessage -match "authentication") {
            Write-Host "Type d'erreur: Problème d'authentification" -ForegroundColor Yellow
            Write-Host "Veuillez vous connecter avec: docker login" -ForegroundColor Yellow
            $success = $false
            break
        } elseif ($errorMessage -match "denied" -or $errorMessage -match "forbidden") {
            Write-Host "Type d'erreur: Accès refusé" -ForegroundColor Yellow
            Write-Host "Vérifiez vos permissions sur Docker Hub" -ForegroundColor Yellow
            $success = $false
            break
        } else {
            Write-Host "Type d'erreur: Autre" -ForegroundColor Yellow
        }
        
        if ($retryCount -lt $MaxRetries) {
            Write-Host ""
            Write-Host "Attente de $RetryDelaySeconds secondes avant la prochaine tentative..." -ForegroundColor Yellow
            Write-Host "(Appuyez sur Ctrl+C pour annuler)" -ForegroundColor Gray
            Start-Sleep -Seconds $RetryDelaySeconds
        } else {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Red
            Write-Host "✗ ÉCHEC APRÈS $MaxRetries TENTATIVES" -ForegroundColor Red
            Write-Host "========================================" -ForegroundColor Red
            Write-Host ""
            Write-Host "Solutions possibles:" -ForegroundColor Yellow
            Write-Host "1. Vérifiez votre connexion Internet" -ForegroundColor White
            Write-Host "2. Vérifiez la configuration du proxy Docker" -ForegroundColor White
            Write-Host "3. Consultez: SOLUTION-ERREUR-DOCKER-PUSH-BROKEN-PIPE.md" -ForegroundColor White
            Write-Host "4. Réessayez manuellement: docker push $ImageName" -ForegroundColor White
            exit 1
        }
    }
}

if ($success) {
    exit 0
} else {
    exit 1
}

