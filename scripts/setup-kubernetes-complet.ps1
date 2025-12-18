# Script de Configuration Complète Kubernetes
# Ce script automatise la plupart des étapes de configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuration Kubernetes Complète" -ForegroundColor Cyan
Write-Host "  Smart Home Load Balancer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que PowerShell est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ ERREUR : Ce script doit être exécuté en tant qu'administrateur !" -ForegroundColor Red
    Write-Host "   Clic droit sur PowerShell → Exécuter en tant qu'administrateur" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PowerShell exécuté en tant qu'administrateur" -ForegroundColor Green
Write-Host ""

# ============================================
# ÉTAPE 1 : Vérifier les Prérequis
# ============================================
Write-Host "=== ÉTAPE 1 : Vérification des Prérequis ===" -ForegroundColor Yellow
Write-Host ""

# Vérifier kubectl
Write-Host "Vérification de kubectl..." -ForegroundColor Gray
try {
    $kubectlVersion = kubectl version --client --short 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ kubectl est installé" -ForegroundColor Green
    } else {
        Write-Host "❌ kubectl n'est pas installé" -ForegroundColor Red
        Write-Host "   Installez-le avec : choco install kubernetes-cli" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ kubectl n'est pas installé" -ForegroundColor Red
    exit 1
}

# Vérifier minikube
Write-Host "Vérification de minikube..." -ForegroundColor Gray
try {
    $minikubeVersion = minikube version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ minikube est installé" -ForegroundColor Green
    } else {
        Write-Host "❌ minikube n'est pas installé" -ForegroundColor Red
        Write-Host "   Installez-le avec : choco install minikube" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ minikube n'est pas installé" -ForegroundColor Red
    exit 1
}

# Vérifier Docker
Write-Host "Vérification de Docker..." -ForegroundColor Gray
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker est installé" -ForegroundColor Green
    } else {
        Write-Host "❌ Docker n'est pas installé ou ne fonctionne pas" -ForegroundColor Red
        Write-Host "   Assurez-vous que Docker Desktop est en cours d'exécution" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Docker n'est pas installé" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Tous les prérequis sont satisfaits" -ForegroundColor Green
Write-Host ""

# ============================================
# ÉTAPE 2 : Démarrer Minikube
# ============================================
Write-Host "=== ÉTAPE 2 : Démarrage de Minikube ===" -ForegroundColor Yellow
Write-Host ""

$minikubeStatus = minikube status 2>&1
if ($LASTEXITCODE -eq 0 -and $minikubeStatus -match "Running") {
    Write-Host "✅ Minikube est déjà en cours d'exécution" -ForegroundColor Green
} else {
    Write-Host "Démarrage de Minikube..." -ForegroundColor Gray
    Write-Host "⏳ Cela peut prendre 2-5 minutes..." -ForegroundColor Yellow
    
    minikube start
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur lors du démarrage de Minikube" -ForegroundColor Red
        Write-Host "   Essayez : minikube start --driver=docker" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Minikube démarré avec succès" -ForegroundColor Green
}

$minikubeIP = minikube ip
Write-Host "📍 IP Minikube : $minikubeIP" -ForegroundColor Cyan
Write-Host ""

# ============================================
# ÉTAPE 3 : Créer le Namespace
# ============================================
Write-Host "=== ÉTAPE 3 : Création du Namespace ===" -ForegroundColor Yellow
Write-Host ""

$namespaceExists = kubectl get namespace smarthome 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Le namespace 'smarthome' existe déjà" -ForegroundColor Green
} else {
    Write-Host "Création du namespace 'smarthome'..." -ForegroundColor Gray
    kubectl apply -f k8s/namespaces/smarthome-namespace.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Namespace créé" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la création du namespace" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# ============================================
# ÉTAPE 4 : Créer les Secrets
# ============================================
Write-Host "=== ÉTAPE 4 : Création des Secrets ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  ATTENTION : Les secrets seront créés avec des valeurs par défaut" -ForegroundColor Yellow
Write-Host "   Vous devrez les modifier manuellement si nécessaire" -ForegroundColor Yellow
Write-Host ""

# Secret PostgreSQL
$postgresSecret = kubectl get secret postgres-secret -n smarthome 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Secret 'postgres-secret' existe déjà" -ForegroundColor Green
} else {
    Write-Host "Création du secret PostgreSQL..." -ForegroundColor Gray
    kubectl create secret generic postgres-secret `
        --from-literal=username=smarthome `
        --from-literal=password=smarthome123 `
        --from-literal=database=smarthome `
        -n smarthome
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Secret PostgreSQL créé" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la création du secret PostgreSQL" -ForegroundColor Red
    }
}

# Secret RabbitMQ
$rabbitmqSecret = kubectl get secret rabbitmq-secret -n smarthome 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Secret 'rabbitmq-secret' existe déjà" -ForegroundColor Green
} else {
    Write-Host "Création du secret RabbitMQ..." -ForegroundColor Gray
    kubectl create secret generic rabbitmq-secret `
        --from-literal=username=guest `
        --from-literal=password=guest123 `
        -n smarthome
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Secret RabbitMQ créé" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la création du secret RabbitMQ" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "⚠️  Note : Si vous utilisez un registry Docker privé," -ForegroundColor Yellow
Write-Host "   créez le secret 'registry-secret' manuellement" -ForegroundColor Yellow
Write-Host ""

# ============================================
# ÉTAPE 5 : Déployer les Bases de Données
# ============================================
Write-Host "=== ÉTAPE 5 : Déploiement des Bases de Données ===" -ForegroundColor Yellow
Write-Host ""

# PostgreSQL
Write-Host "Déploiement de PostgreSQL..." -ForegroundColor Gray
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ PostgreSQL déployé" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du déploiement de PostgreSQL" -ForegroundColor Red
}

Write-Host "⏳ Attente que PostgreSQL soit prêt..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# ============================================
# ÉTAPE 6 : Déployer RabbitMQ
# ============================================
Write-Host ""
Write-Host "=== ÉTAPE 6 : Déploiement de RabbitMQ ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Déploiement de RabbitMQ..." -ForegroundColor Gray
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RabbitMQ déployé" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du déploiement de RabbitMQ" -ForegroundColor Red
}

Write-Host "⏳ Attente que RabbitMQ soit prêt..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# ============================================
# ÉTAPE 7 : Déployer les Services
# ============================================
Write-Host ""
Write-Host "=== ÉTAPE 7 : Déploiement des Services ===" -ForegroundColor Yellow
Write-Host ""

$services = @(
    "usage-collector",
    "peak-detector",
    "optimizer",
    "device-simulator",
    "frontend"
)

foreach ($service in $services) {
    Write-Host "Déploiement de $service-service..." -ForegroundColor Gray
    kubectl apply -f "k8s/services/$service/deployment.yaml"
    kubectl apply -f "k8s/services/$service/service.yaml"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $service-service déployé" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors du déploiement de $service-service" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "⏳ Attente que les services démarrent..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# ============================================
# ÉTAPE 8 : Configurer l'Ingress
# ============================================
Write-Host ""
Write-Host "=== ÉTAPE 8 : Configuration de l'Ingress ===" -ForegroundColor Yellow
Write-Host ""

# Activer l'Ingress Controller
Write-Host "Activation de l'Ingress Controller..." -ForegroundColor Gray
minikube addons enable ingress

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ingress Controller activé" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors de l'activation de l'Ingress Controller" -ForegroundColor Red
}

Write-Host "⏳ Attente que l'Ingress Controller soit prêt..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Appliquer l'Ingress
Write-Host "Application de la configuration Ingress..." -ForegroundColor Gray
kubectl apply -f k8s/ingress/ingress.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ingress configuré" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors de la configuration de l'Ingress" -ForegroundColor Red
}

# ============================================
# RÉSUMÉ
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CONFIGURATION TERMINÉE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Prochaines Étapes :" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Configurer le fichier hosts :" -ForegroundColor Cyan
Write-Host "   - Ouvrir C:\Windows\System32\drivers\etc\hosts en tant qu'administrateur" -ForegroundColor White
Write-Host "   - Ajouter : $minikubeIP smarthome.local" -ForegroundColor White
Write-Host ""

Write-Host "2. Vérifier l'état des pods :" -ForegroundColor Cyan
Write-Host "   kubectl get pods -n smarthome" -ForegroundColor White
Write-Host ""

Write-Host "3. Tester avec Postman :" -ForegroundColor Cyan
Write-Host "   GET http://smarthome.local/usage/current" -ForegroundColor White
Write-Host "   GET http://smarthome.local/optimizer/health" -ForegroundColor White
Write-Host ""

Write-Host "4. Voir les logs si nécessaire :" -ForegroundColor Cyan
Write-Host "   kubectl logs -n smarthome -l app=usage-collector-service --tail=50" -ForegroundColor White
Write-Host ""

Write-Host "✅ Configuration terminée !" -ForegroundColor Green
Write-Host ""

