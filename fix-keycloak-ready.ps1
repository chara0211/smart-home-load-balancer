# Script PowerShell pour corriger le problème "Keycloak Never Ready"
# Usage: .\fix-keycloak-ready.ps1

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Solution Keycloak - Pod Never Ready" -ForegroundColor Cyan
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
Write-Host "Étape 1/3: Application de la nouvelle configuration Keycloak..." -ForegroundColor Yellow
Write-Host ""

# Appliquer la configuration
Write-Host "  Application: keycloak-deployment.yaml..." -NoNewline
try {
    kubectl apply -f k8s/keycloak/keycloak-deployment.yaml -n smarthome 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "Erreur lors de l'application de la configuration" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "    Erreur: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Étape 2/3: Vérification des prérequis..." -ForegroundColor Yellow
Write-Host ""

# Vérifier que PostgreSQL est accessible
Write-Host "  Vérification: PostgreSQL service..." -NoNewline
try {
    $pgService = kubectl get svc postgres-service -n smarthome 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Yellow
        Write-Host "    Avertissement: Le service postgres-service n'existe pas" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ✗" -ForegroundColor Yellow
    Write-Host "    Avertissement: Impossible de vérifier PostgreSQL" -ForegroundColor Yellow
}

# Vérifier que le secret existe
Write-Host "  Vérification: postgres-secret..." -NoNewline
try {
    $secret = kubectl get secret postgres-secret -n smarthome 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Yellow
        Write-Host "    Avertissement: Le secret postgres-secret n'existe pas" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ✗" -ForegroundColor Yellow
    Write-Host "    Avertissement: Impossible de vérifier le secret" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Étape 3/3: Redémarrage du déploiement Keycloak..." -ForegroundColor Yellow
Write-Host ""

# Attendre quelques secondes
Write-Host "Attente de 5 secondes pour que Kubernetes intègre les changements..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Redémarrer le déploiement
Write-Host "  Redémarrage: keycloak..." -NoNewline
try {
    kubectl rollout restart deployment/keycloak -n smarthome 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Red
        Write-Host "Erreur lors du redémarrage" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ✗" -ForegroundColor Red
    Write-Host "    Erreur: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Configuration appliquée avec succès!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Surveillance de l'état du pod Keycloak..." -ForegroundColor Yellow
Write-Host ""

# Afficher l'état actuel
kubectl get pods -n smarthome -l app=keycloak

Write-Host ""
Write-Host "Changements appliqués:" -ForegroundColor Cyan
Write-Host "  ✓ Health checks activés (KC_HEALTH_ENABLED=true)" -ForegroundColor White
Write-Host "  ✓ InitContainer ajouté pour attendre PostgreSQL" -ForegroundColor White
Write-Host "  ✓ StartupProbe: jusqu'à 20 minutes de démarrage autorisé" -ForegroundColor White
Write-Host "  ✓ ReadinessProbe: 10 échecs tolérés" -ForegroundColor White
Write-Host "  ✓ Ressources augmentées (CPU: 750m→1500m, Memory: 1.5Gi→3Gi)" -ForegroundColor White
Write-Host ""

Write-Host "Commandes utiles:" -ForegroundColor Cyan
Write-Host "  # Surveiller en temps réel" -ForegroundColor White
Write-Host "  kubectl get pods -n smarthome -l app=keycloak -w" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Voir les logs" -ForegroundColor White
Write-Host "  kubectl logs -n smarthome -l app=keycloak -f" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Voir les logs de l'initContainer" -ForegroundColor White
Write-Host "  kubectl logs -n smarthome <pod-name> -c wait-for-postgres" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Tester les endpoints de santé (après port-forward)" -ForegroundColor White
Write-Host "  kubectl port-forward -n smarthome svc/keycloak-service 8080:8080" -ForegroundColor Gray
Write-Host "  # Puis: curl http://localhost:8080/health/ready" -ForegroundColor Gray
Write-Host ""

Write-Host "Timeline attendu:" -ForegroundColor Cyan
Write-Host "  - InitContainer: 0-30 secondes" -ForegroundColor White
Write-Host "  - Build Keycloak (première fois): 3-5 minutes" -ForegroundColor White
Write-Host "  - Démarrage Keycloak: 5-10 minutes" -ForegroundColor White
Write-Host "  - Total (première fois): 10-15 minutes" -ForegroundColor White
Write-Host "  - Total (suivant): 5-8 minutes" -ForegroundColor White
Write-Host ""

Write-Host "Le pod Keycloak devrait devenir Ready dans les prochaines minutes." -ForegroundColor Green






