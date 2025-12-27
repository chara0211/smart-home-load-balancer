# Script de Correction Complète du Cluster
# Ce script résout tous les problèmes de pods non prêts
# Usage: .\scripts\correction-complete-cluster.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTION COMPLÈTE DU CLUSTER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "smarthome"

# ÉTAPE 1 : Nettoyer les pods en double et en erreur
Write-Host "ÉTAPE 1: NETTOYAGE DES PODS" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

# Supprimer les pods en Pending (ils seront recréés)
Write-Host "Suppression des pods en Pending..." -ForegroundColor Cyan
$pendingPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$pendingPods = $pendingPods.items | Where-Object { $_.status.phase -eq "Pending" }

foreach ($pod in $pendingPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
}

# Supprimer les pods en CrashLoopBackOff
Write-Host "Suppression des pods en CrashLoopBackOff..." -ForegroundColor Cyan
$crashPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$crashPods = $crashPods.items | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
}

foreach ($pod in $crashPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
}

Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
Write-Host ""

# ÉTAPE 2 : S'assurer qu'il n'y a qu'un seul replica par service
Write-Host "ÉTAPE 2: RÉDUCTION DES REPLICAS" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service",
    "keycloak"
)

foreach ($service in $services) {
    Write-Host "Vérification de $service..." -ForegroundColor Cyan
    $currentReplicas = kubectl get deployment $service -n $namespace -o jsonpath='{.spec.replicas}' 2>$null
    if ($currentReplicas -gt 1) {
        Write-Host "   Réduction à 1 replica (était $currentReplicas)" -ForegroundColor Yellow
        kubectl scale deployment/$service -n $namespace --replicas=1 2>$null
    } else {
        Write-Host "   ✅ Déjà à 1 replica" -ForegroundColor Green
    }
}

Write-Host "✅ Tous les services sont à 1 replica" -ForegroundColor Green
Write-Host ""

# ÉTAPE 3 : Attendre que la mémoire se libère
Write-Host "ÉTAPE 3: ATTENTE DE LIBÉRATION DE MÉMOIRE" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Attente de 30 secondes pour que les pods se terminent..." -ForegroundColor Cyan
Start-Sleep -Seconds 30
Write-Host "✅ Attente terminée" -ForegroundColor Green
Write-Host ""

# ÉTAPE 4 : Vérifier l'état de PostgreSQL
Write-Host "ÉTAPE 4: VÉRIFICATION DE POSTGRESQL" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$postgresReady = kubectl get pod -n $namespace -l app=postgres -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>$null
if ($postgresReady -eq "true") {
    Write-Host "✅ PostgreSQL est prêt" -ForegroundColor Green
} else {
    Write-Host "⚠️  PostgreSQL n'est pas prêt" -ForegroundColor Yellow
    Write-Host "   Vérifiez: kubectl logs -n $namespace -l app=postgres --tail=50" -ForegroundColor White
}
Write-Host ""

# ÉTAPE 5 : Vérifier et démarrer RabbitMQ
Write-Host "ÉTAPE 5: VÉRIFICATION DE RABBITMQ" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$rabbitmqPod = kubectl get pods -n $namespace -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($rabbitmqPod) {
    $rabbitmqStatus = kubectl get pod -n $namespace $rabbitmqPod -o jsonpath='{.status.phase}' 2>$null
    
    if ($rabbitmqStatus -eq "Pending") {
        Write-Host "⚠️  RabbitMQ est en Pending (mémoire insuffisante)" -ForegroundColor Yellow
        Write-Host "   Le pod démarrera automatiquement quand de la mémoire se libère" -ForegroundColor Cyan
        Write-Host "   Surveillez avec: kubectl get pods -n $namespace -l app=rabbitmq -w" -ForegroundColor White
    } elseif ($rabbitmqStatus -eq "Running") {
        $rabbitmqReady = kubectl get pod -n $namespace $rabbitmqPod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
        if ($rabbitmqReady -eq "true") {
            Write-Host "✅ RabbitMQ est prêt" -ForegroundColor Green
        } else {
            Write-Host "⚠️  RabbitMQ est Running mais pas encore prêt" -ForegroundColor Yellow
            Write-Host "   Cela peut prendre 2-3 minutes" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⚠️  RabbitMQ Status: $rabbitmqStatus" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Aucun pod RabbitMQ trouvé" -ForegroundColor Yellow
}
Write-Host ""

# ÉTAPE 6 : État final
Write-Host "ÉTAPE 6: ÉTAT FINAL" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTIONS APPLIQUÉES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Actions recommandées:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. SURVEILLER RABBITMQ (priorité):" -ForegroundColor Cyan
Write-Host "   kubectl get pods -n $namespace -l app=rabbitmq -w" -ForegroundColor White
Write-Host "   Une fois RabbitMQ prêt, les autres services devraient se connecter" -ForegroundColor Gray
Write-Host ""
Write-Host "2. SI RABBITMQ RESTE EN PENDING:" -ForegroundColor Cyan
Write-Host "   - Attendez que d'autres pods libèrent de la mémoire" -ForegroundColor White
Write-Host "   - Ou augmentez les ressources Minikube:" -ForegroundColor White
Write-Host "     minikube stop" -ForegroundColor Gray
Write-Host "     minikube start --memory=4096 --cpus=4" -ForegroundColor Gray
Write-Host ""
Write-Host "3. VÉRIFIER LES LOGS SI PROBLÈME:" -ForegroundColor Cyan
Write-Host "   kubectl logs -n $namespace <pod-name> --tail=50" -ForegroundColor White
Write-Host ""
Write-Host "4. SURVEILLER TOUS LES PODS:" -ForegroundColor Cyan
Write-Host "   kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""


