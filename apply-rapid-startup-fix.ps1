# Script PowerShell pour appliquer la solution radicale de démarrage rapide
# Usage: .\apply-rapid-startup-fix.ps1

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Solution Radicale - Démarrage Rapide des Pods" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que kubectl est disponible
try {
    $kubectlVersion = kubectl version --client --short 2>&1
    Write-Host "✓ kubectl détecté" -ForegroundColor Green
} catch {
    Write-Host "✗ kubectl n'est pas installé ou non disponible dans le PATH" -ForegroundColor Red
    exit 1
}

# Vérifier la connexion au cluster
Write-Host "Vérification de la connexion au cluster..." -ForegroundColor Yellow
try {
    $context = kubectl config current-context 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Pas de contexte Kubernetes actif"
    }
    Write-Host "✓ Connexion au cluster: $context" -ForegroundColor Green
} catch {
    Write-Host "✗ Impossible de se connecter au cluster Kubernetes" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Étape 1/3: Application des nouvelles configurations..." -ForegroundColor Yellow
Write-Host ""

# Liste des déploiements à mettre à jour
$deployments = @(
    @{Path="k8s/databases/postgres-deployment.yaml"; Name="PostgreSQL"},
    @{Path="k8s/message-broker/rabbitmq-deployment.yaml"; Name="RabbitMQ"},
    @{Path="k8s/keycloak/keycloak-deployment.yaml"; Name="Keycloak"},
    @{Path="k8s/services/usage-collector/deployment.yaml"; Name="Usage Collector Service"},
    @{Path="k8s/services/peak-detector/deployment.yaml"; Name="Peak Detector Service"},
    @{Path="k8s/services/optimizer/deployment.yaml"; Name="Optimizer Service"},
    @{Path="k8s/services/billing/deployment.yaml"; Name="Billing Service"},
    @{Path="k8s/services/device-simulator/deployment.yaml"; Name="Device Simulator Service"}
)

$successCount = 0
$failCount = 0

foreach ($deployment in $deployments) {
    Write-Host "  Application: $($deployment.Name)..." -NoNewline
    try {
        kubectl apply -f $deployment.Path -n smarthome 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host " ✗" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "    Erreur: $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "Résultat: $successCount succès, $failCount échecs" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "Certains déploiements ont échoué. Vérifiez les erreurs ci-dessus." -ForegroundColor Yellow
    $continue = Read-Host "Continuer avec le redémarrage des pods? (o/N)"
    if ($continue -ne "o" -and $continue -ne "O") {
        exit 1
    }
}

Write-Host "Attente de 5 secondes pour que Kubernetes intègre les changements..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "Étape 2/3: Redémarrage forcé des déploiements..." -ForegroundColor Yellow
Write-Host ""

$deploymentNames = @(
    "postgres",
    "rabbitmq",
    "keycloak",
    "usage-collector-service",
    "peak-detector-service",
    "optimizer-service",
    "billing-service",
    "device-simulator-service"
)

$restartSuccessCount = 0
$restartFailCount = 0

foreach ($deploymentName in $deploymentNames) {
    Write-Host "  Redémarrage: $deploymentName..." -NoNewline
    try {
        kubectl rollout restart deployment/$deploymentName -n smarthome 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓" -ForegroundColor Green
            $restartSuccessCount++
        } else {
            Write-Host " ✗" -ForegroundColor Red
            $restartFailCount++
        }
    } catch {
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "    Erreur: $_" -ForegroundColor Red
        $restartFailCount++
    }
}

Write-Host ""
Write-Host "Résultat: $restartSuccessCount redémarrages initiés, $restartFailCount échecs" -ForegroundColor $(if ($restartFailCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

Write-Host "Étape 3/3: Surveillance de l'état des pods..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Les pods sont en cours de redémarrage avec les nouvelles configurations." -ForegroundColor Cyan
Write-Host "Avec les nouvelles ressources et probes, le démarrage devrait être beaucoup plus rapide." -ForegroundColor Cyan
Write-Host ""
Write-Host "Surveillance en temps réel (appuyez sur Ctrl+C pour arrêter)..." -ForegroundColor Yellow
Write-Host ""

# Afficher l'état actuel
kubectl get pods -n smarthome

Write-Host ""
Write-Host "Pour surveiller en continu, exécutez:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n smarthome -w" -ForegroundColor White
Write-Host ""
Write-Host "Pour voir les événements récents:" -ForegroundColor Cyan
Write-Host "  kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 50" -ForegroundColor White
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Application terminée!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan







