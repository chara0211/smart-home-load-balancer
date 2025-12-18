# Script de Vérification de la Configuration Kubernetes
# Vérifie que tous les composants sont correctement configurés

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Vérification de la Configuration" -ForegroundColor Cyan
Write-Host "  Smart Home Load Balancer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# ============================================
# Vérification 1 : Minikube
# ============================================
Write-Host "1. Vérification de Minikube..." -ForegroundColor Yellow
$minikubeStatus = minikube status 2>&1
if ($LASTEXITCODE -eq 0 -and $minikubeStatus -match "Running") {
    $minikubeIP = minikube ip
    Write-Host "   ✅ Minikube est en cours d'exécution (IP: $minikubeIP)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Minikube n'est pas en cours d'exécution" -ForegroundColor Red
    $errors++
}
Write-Host ""

# ============================================
# Vérification 2 : Namespace
# ============================================
Write-Host "2. Vérification du Namespace..." -ForegroundColor Yellow
$namespace = kubectl get namespace smarthome 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Namespace 'smarthome' existe" -ForegroundColor Green
} else {
    Write-Host "   ❌ Namespace 'smarthome' n'existe pas" -ForegroundColor Red
    $errors++
}
Write-Host ""

# ============================================
# Vérification 3 : Secrets
# ============================================
Write-Host "3. Vérification des Secrets..." -ForegroundColor Yellow

$requiredSecrets = @("postgres-secret", "rabbitmq-secret")
foreach ($secret in $requiredSecrets) {
    $secretExists = kubectl get secret $secret -n smarthome 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Secret '$secret' existe" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Secret '$secret' n'existe pas" -ForegroundColor Red
        $errors++
    }
}

$registrySecret = kubectl get secret registry-secret -n smarthome 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Secret 'registry-secret' existe" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Secret 'registry-secret' n'existe pas (optionnel si pas de registry privé)" -ForegroundColor Yellow
    $warnings++
}
Write-Host ""

# ============================================
# Vérification 4 : Bases de Données
# ============================================
Write-Host "4. Vérification des Bases de Données..." -ForegroundColor Yellow

# PostgreSQL
$postgresPods = kubectl get pods -n smarthome -l app=postgres 2>&1
if ($LASTEXITCODE -eq 0) {
    $postgresRunning = kubectl get pods -n smarthome -l app=postgres -o jsonpath='{.items[0].status.phase}' 2>&1
    $postgresReady = kubectl get pods -n smarthome -l app=postgres -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>&1
    
    if ($postgresRunning -eq "Running" -and $postgresReady -eq "true") {
        Write-Host "   ✅ PostgreSQL est en cours d'exécution et prêt" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  PostgreSQL est en cours de démarrage..." -ForegroundColor Yellow
        $warnings++
    }
} else {
    Write-Host "   ❌ PostgreSQL n'est pas déployé" -ForegroundColor Red
    $errors++
}
Write-Host ""

# ============================================
# Vérification 5 : RabbitMQ
# ============================================
Write-Host "5. Vérification de RabbitMQ..." -ForegroundColor Yellow

$rabbitmqPods = kubectl get pods -n smarthome -l app=rabbitmq 2>&1
if ($LASTEXITCODE -eq 0) {
    $rabbitmqRunning = kubectl get pods -n smarthome -l app=rabbitmq -o jsonpath='{.items[0].status.phase}' 2>&1
    $rabbitmqReady = kubectl get pods -n smarthome -l app=rabbitmq -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>&1
    
    if ($rabbitmqRunning -eq "Running" -and $rabbitmqReady -eq "true") {
        Write-Host "   ✅ RabbitMQ est en cours d'exécution et prêt" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  RabbitMQ est en cours de démarrage..." -ForegroundColor Yellow
        $warnings++
    }
} else {
    Write-Host "   ❌ RabbitMQ n'est pas déployé" -ForegroundColor Red
    $errors++
}
Write-Host ""

# ============================================
# Vérification 6 : Services
# ============================================
Write-Host "6. Vérification des Services..." -ForegroundColor Yellow

$services = @(
    @{Name="usage-collector-service"; Label="app=usage-collector-service"},
    @{Name="peak-detector-service"; Label="app=peak-detector-service"},
    @{Name="optimizer-service"; Label="app=optimizer-service"},
    @{Name="device-simulator-service"; Label="app=device-simulator-service"}
)

foreach ($service in $services) {
    $pods = kubectl get pods -n smarthome -l $service.Label 2>&1
    if ($LASTEXITCODE -eq 0) {
        $running = kubectl get pods -n smarthome -l $service.Label -o jsonpath='{.items[0].status.phase}' 2>&1
        $ready = kubectl get pods -n smarthome -l $service.Label -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>&1
        
        if ($running -eq "Running" -and $ready -eq "true") {
            Write-Host "   ✅ $($service.Name) est en cours d'exécution et prêt" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  $($service.Name) est en cours de démarrage..." -ForegroundColor Yellow
            $warnings++
        }
    } else {
        Write-Host "   ❌ $($service.Name) n'est pas déployé" -ForegroundColor Red
        $errors++
    }
}
Write-Host ""

# ============================================
# Vérification 7 : Ingress
# ============================================
Write-Host "7. Vérification de l'Ingress..." -ForegroundColor Yellow

$ingress = kubectl get ingress smarthome-ingress -n smarthome 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Ingress 'smarthome-ingress' existe" -ForegroundColor Green
    
    # Vérifier l'Ingress Controller
    $ingressController = kubectl get pods -n ingress-nginx 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Ingress Controller est actif" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Ingress Controller n'est pas actif" -ForegroundColor Yellow
        Write-Host "      Exécutez : minikube addons enable ingress" -ForegroundColor Gray
        $warnings++
    }
} else {
    Write-Host "   ❌ Ingress 'smarthome-ingress' n'existe pas" -ForegroundColor Red
    $errors++
}
Write-Host ""

# ============================================
# Vérification 8 : Fichier Hosts
# ============================================
Write-Host "8. Vérification du Fichier Hosts..." -ForegroundColor Yellow

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
if (Test-Path $hostsPath) {
    $hostsContent = Get-Content $hostsPath
    $minikubeIP = minikube ip 2>&1
    
    if ($hostsContent -match "smarthome.local") {
        Write-Host "   ✅ Entrée 'smarthome.local' trouvée dans hosts" -ForegroundColor Green
        
        # Vérifier que l'IP correspond
        $hostsLine = $hostsContent | Where-Object { $_ -match "smarthome.local" }
        if ($hostsLine -match $minikubeIP) {
            Write-Host "   ✅ L'IP dans hosts correspond à Minikube" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  L'IP dans hosts ne correspond pas à Minikube" -ForegroundColor Yellow
            Write-Host "      IP Minikube : $minikubeIP" -ForegroundColor Gray
            Write-Host "      Mettez à jour le fichier hosts avec cette IP" -ForegroundColor Gray
            $warnings++
        }
    } else {
        Write-Host "   ❌ Entrée 'smarthome.local' non trouvée dans hosts" -ForegroundColor Red
        Write-Host "      Ajoutez : $minikubeIP smarthome.local" -ForegroundColor Gray
        $errors++
    }
} else {
    Write-Host "   ❌ Impossible d'accéder au fichier hosts" -ForegroundColor Red
    $errors++
}
Write-Host ""

# ============================================
# Résumé
# ============================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RÉSUMÉ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "✅ Tous les composants sont correctement configurés !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous pouvez maintenant tester avec Postman :" -ForegroundColor Cyan
    Write-Host "   GET http://smarthome.local/usage/current" -ForegroundColor White
    Write-Host "   GET http://smarthome.local/optimizer/health" -ForegroundColor White
} elseif ($errors -eq 0) {
    Write-Host "⚠️  Configuration presque complète avec $warnings avertissement(s)" -ForegroundColor Yellow
    Write-Host "   Vérifiez les avertissements ci-dessus" -ForegroundColor Yellow
} else {
    Write-Host "❌ Configuration incomplète : $errors erreur(s) et $warnings avertissement(s)" -ForegroundColor Red
    Write-Host "   Corrigez les erreurs avant de continuer" -ForegroundColor Red
}

Write-Host ""

# Afficher l'état détaillé des pods
Write-Host "État détaillé des pods :" -ForegroundColor Cyan
kubectl get pods -n smarthome
Write-Host ""

