# Script de Déploiement de Tous les Services
# Déploie tous les services backend et frontend sur Kubernetes

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Déploiement de Tous les Services" -ForegroundColor Cyan
Write-Host "  Smart Home Load Balancer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$NAMESPACE = "smarthome"

# Fonction pour attendre qu'un pod soit prêt
function Wait-ForPod {
    param(
        [string]$Selector,
        [int]$Timeout = 300
    )
    
    Write-Host "⏳ Attente que le pod '$Selector' soit prêt (timeout: ${Timeout}s)..." -ForegroundColor Yellow
    
    $startTime = Get-Date
    do {
        $pods = kubectl get pods -n $NAMESPACE -l $Selector -o json 2>&1 | ConvertFrom-Json
        $readyPods = $pods.items | Where-Object { 
            $_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
        }
        
        if ($readyPods.Count -gt 0) {
            Write-Host "✅ Pod(s) prêt(s)" -ForegroundColor Green
            return $true
        }
        
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -gt $Timeout) {
            Write-Host "❌ Timeout : Le pod n'est pas prêt dans le délai imparti" -ForegroundColor Red
            kubectl get pods -n $NAMESPACE -l $Selector
            return $false
        }
        
        Start-Sleep -Seconds 5
    } while ($true)
}

# ============================================
# ÉTAPE 1 : Vérifier le Namespace
# ============================================
Write-Host "=== ÉTAPE 1 : Vérification du Namespace ===" -ForegroundColor Yellow
Write-Host ""

$namespaceExists = kubectl get namespace $NAMESPACE 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Création du namespace '$NAMESPACE'..." -ForegroundColor Gray
    kubectl apply -f k8s/namespaces/smarthome-namespace.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Namespace créé" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la création du namespace" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Le namespace '$NAMESPACE' existe déjà" -ForegroundColor Green
}
Write-Host ""

# ============================================
# ÉTAPE 2 : Déployer PostgreSQL
# ============================================
Write-Host "=== ÉTAPE 2 : Déploiement de PostgreSQL ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Déploiement de PostgreSQL..." -ForegroundColor Gray
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ PostgreSQL déployé" -ForegroundColor Green
    Wait-ForPod -Selector "app=postgres" -Timeout 300
} else {
    Write-Host "❌ Erreur lors du déploiement de PostgreSQL" -ForegroundColor Red
}
Write-Host ""

# ============================================
# ÉTAPE 3 : Déployer RabbitMQ
# ============================================
Write-Host "=== ÉTAPE 3 : Déploiement de RabbitMQ ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Déploiement de RabbitMQ..." -ForegroundColor Gray
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RabbitMQ déployé" -ForegroundColor Green
    Wait-ForPod -Selector "app=rabbitmq" -Timeout 300
} else {
    Write-Host "❌ Erreur lors du déploiement de RabbitMQ" -ForegroundColor Red
}
Write-Host ""

# ============================================
# ÉTAPE 4 : Déployer les Services Backend
# ============================================
Write-Host "=== ÉTAPE 4 : Déploiement des Services Backend ===" -ForegroundColor Yellow
Write-Host ""

$backendServices = @(
    @{Name = "usage-collector"; DisplayName = "Usage Collector Service"},
    @{Name = "device-simulator"; DisplayName = "Device Simulator Service"},
    @{Name = "peak-detector"; DisplayName = "Peak Detector Service"},
    @{Name = "optimizer"; DisplayName = "Optimizer Service"},
    @{Name = "billing"; DisplayName = "Billing Service"}
)

foreach ($service in $backendServices) {
    Write-Host "Déploiement de $($service.DisplayName)..." -ForegroundColor Gray
    
    $deploymentFile = "k8s/services/$($service.Name)/deployment.yaml"
    $serviceFile = "k8s/services/$($service.Name)/service.yaml"
    
    if (Test-Path $deploymentFile) {
        kubectl apply -f $deploymentFile
    } else {
        Write-Host "⚠️  Fichier de déploiement non trouvé : $deploymentFile" -ForegroundColor Yellow
    }
    
    if (Test-Path $serviceFile) {
        kubectl apply -f $serviceFile
    } else {
        Write-Host "⚠️  Fichier de service non trouvé : $serviceFile" -ForegroundColor Yellow
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $($service.DisplayName) déployé" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors du déploiement de $($service.DisplayName)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "⏳ Attente que les services backend démarrent..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# ============================================
# ÉTAPE 5 : Déployer le Frontend
# ============================================
Write-Host "=== ÉTAPE 5 : Déploiement du Frontend ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Déploiement du Frontend..." -ForegroundColor Gray
kubectl apply -f k8s/services/frontend/deployment.yaml
kubectl apply -f k8s/services/frontend/service.yaml

# Déployer aussi le service NodePort (optionnel)
if (Test-Path "k8s/services/frontend/service-nodeport.yaml") {
    Write-Host "Déploiement du service NodePort pour le frontend..." -ForegroundColor Gray
    kubectl apply -f k8s/services/frontend/service-nodeport.yaml
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Frontend déployé" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du déploiement du Frontend" -ForegroundColor Red
}
Write-Host ""

# ============================================
# ÉTAPE 6 : Vérification Finale
# ============================================
Write-Host "=== ÉTAPE 6 : Vérification du Déploiement ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 État des pods:" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE
Write-Host ""

Write-Host "📋 État des services:" -ForegroundColor Cyan
kubectl get services -n $NAMESPACE
Write-Host ""

# ============================================
# RÉSUMÉ
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DÉPLOIEMENT TERMINÉ" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 Commandes utiles :" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Voir tous les pods :" -ForegroundColor White
Write-Host "    kubectl get pods -n $NAMESPACE" -ForegroundColor Gray
Write-Host ""
Write-Host "  Voir les logs d'un service :" -ForegroundColor White
Write-Host "    kubectl logs -f deployment/<service-name> -n $NAMESPACE" -ForegroundColor Gray
Write-Host ""
Write-Host "  Accéder au frontend (Port-Forward) :" -ForegroundColor White
Write-Host "    kubectl port-forward service/frontend-service 3000:3000 -n $NAMESPACE" -ForegroundColor Gray
Write-Host "    Puis ouvrir : http://localhost:3000" -ForegroundColor Gray
Write-Host ""

# Obtenir l'IP de Minikube si disponible
try {
    $minikubeIP = minikube ip 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🌐 Accès via NodePort (si configuré) :" -ForegroundColor Yellow
        Write-Host "    Frontend : http://$minikubeIP`:30000" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    # Minikube n'est pas disponible, on ignore
}

Write-Host "✅ Tous les services ont été déployés !" -ForegroundColor Green
Write-Host ""

