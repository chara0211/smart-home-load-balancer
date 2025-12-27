# Script d'urgence pour libérer de la mémoire
# Supprime les pods en double et réduit les ressources

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LIBÉRATION URGENTE DE MÉMOIRE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Supprimer les pods en double (garder seulement le plus récent)
Write-Host "1. Suppression des pods en double..." -ForegroundColor Yellow

$services = @(
    "billing-service",
    "device-simulator-service",
    "optimizer-service",
    "peak-detector-service",
    "usage-collector-service"
)

foreach ($service in $services) {
    $pods = kubectl get pods -n $namespace -l app=$service -o json | ConvertFrom-Json
    $pods = $pods.items | Where-Object { $_.status.phase -eq "Running" } | Sort-Object { $_.metadata.creationTimestamp } -Descending
    
    if ($pods.Count -gt 1) {
        Write-Host "   $service : $($pods.Count) pods trouvés" -ForegroundColor Cyan
        # Garder le premier (le plus récent), supprimer les autres
        for ($i = 1; $i -lt $pods.Count; $i++) {
            $podName = $pods[$i].metadata.name
            Write-Host "     Suppression: $podName" -ForegroundColor Gray
            kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
        }
    }
}

Write-Host "✅ Pods en double supprimés" -ForegroundColor Green
Write-Host ""

# 2. Supprimer les pods en CrashLoopBackOff
Write-Host "2. Suppression des pods en CrashLoopBackOff..." -ForegroundColor Yellow
$crashPods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
$crashPods = $crashPods.items | Where-Object { 
    $_.status.containerStatuses | Where-Object { $_.state.waiting.reason -eq "CrashLoopBackOff" }
}

foreach ($pod in $crashPods) {
    $podName = $pod.metadata.name
    Write-Host "   Suppression: $podName" -ForegroundColor Gray
    kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
}

Write-Host "✅ Pods en erreur supprimés" -ForegroundColor Green
Write-Host ""

# 3. Appliquer la configuration RabbitMQ réduite
Write-Host "3. Application de la configuration RabbitMQ réduite..." -ForegroundColor Yellow
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
Write-Host "✅ Configuration appliquée" -ForegroundColor Green
Write-Host ""

# 4. Supprimer les pods RabbitMQ en Pending
Write-Host "4. Suppression des pods RabbitMQ en Pending..." -ForegroundColor Yellow
kubectl delete pod -n $namespace -l app=rabbitmq --grace-period=0 --force 2>$null
Write-Host "✅ Pods RabbitMQ supprimés" -ForegroundColor Green
Write-Host ""

# 5. Attendre un peu
Write-Host "5. Attente de 20 secondes pour que la mémoire se libère..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
Write-Host "✅ Attente terminée" -ForegroundColor Green
Write-Host ""

# 6. État final
Write-Host "6. ÉTAT FINAL" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTIONS APPLIQUÉES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Mémoire libérée en:" -ForegroundColor Yellow
Write-Host "  ✅ Suppression des pods en double" -ForegroundColor Green
Write-Host "  ✅ Suppression des pods en erreur" -ForegroundColor Green
Write-Host "  ✅ Réduction des ressources RabbitMQ à 256Mi" -ForegroundColor Green
Write-Host ""
Write-Host "Surveillez RabbitMQ:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -l app=rabbitmq -w" -ForegroundColor White
Write-Host ""


