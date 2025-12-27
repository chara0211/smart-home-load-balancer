# Script pour nettoyer définitivement les pods en double
# Usage: .\scripts\nettoyer-pods-doubles-final.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NETTOYAGE DÉFINITIF DES PODS EN DOUBLE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# S'assurer qu'il n'y a qu'un seul replica par service
Write-Host "1. Vérification et réduction des replicas..." -ForegroundColor Yellow

$services = @(
    "billing-service",
    "usage-collector-service",
    "optimizer-service",
    "peak-detector-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    $currentReplicas = kubectl get deployment $service -n $namespace -o jsonpath='{.spec.replicas}' 2>$null
    if ($currentReplicas -gt 1) {
        Write-Host "   $service : Réduction de $currentReplicas à 1" -ForegroundColor Yellow
        kubectl scale deployment/$service -n $namespace --replicas=1 2>$null
    }
}

Write-Host "✅ Tous les services sont à 1 replica" -ForegroundColor Green
Write-Host ""

# Supprimer les pods en double (garder seulement le plus récent)
Write-Host "2. Suppression des pods en double..." -ForegroundColor Yellow

foreach ($service in $services) {
    $pods = kubectl get pods -n $namespace -l app=$service -o json | ConvertFrom-Json
    $runningPods = $pods.items | Where-Object { $_.status.phase -eq "Running" } | Sort-Object { $_.metadata.creationTimestamp } -Descending
    
    if ($runningPods.Count -gt 1) {
        Write-Host "   $service : $($runningPods.Count) pods trouvés" -ForegroundColor Cyan
        # Garder le premier (le plus récent), supprimer les autres
        for ($i = 1; $i -lt $runningPods.Count; $i++) {
            $podName = $runningPods[$i].metadata.name
            Write-Host "     Suppression: $podName" -ForegroundColor Gray
            kubectl delete pod -n $namespace $podName --grace-period=0 --force 2>$null
        }
    }
}

Write-Host "✅ Pods en double supprimés" -ForegroundColor Green
Write-Host ""

# Supprimer les anciens ReplicaSets
Write-Host "3. Nettoyage des anciens ReplicaSets..." -ForegroundColor Yellow

foreach ($service in $services) {
    $replicasets = kubectl get replicaset -n $namespace -l app=$service -o json | ConvertFrom-Json
    $activeRS = $replicasets.items | Where-Object { $_.spec.replicas -gt 0 } | Sort-Object { $_.metadata.creationTimestamp } -Descending
    
    if ($activeRS.Count -gt 1) {
        Write-Host "   $service : $($activeRS.Count) ReplicaSets actifs" -ForegroundColor Cyan
        # Garder le premier (le plus récent), mettre les autres à 0
        for ($i = 1; $i -lt $activeRS.Count; $i++) {
            $rsName = $activeRS[$i].metadata.name
            Write-Host "     Mise à 0: $rsName" -ForegroundColor Gray
            kubectl scale replicaset $rsName -n $namespace --replicas=0 2>$null
        }
    }
}

Write-Host "✅ ReplicaSets nettoyés" -ForegroundColor Green
Write-Host ""

# État final
Write-Host "4. ÉTAT FINAL" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
kubectl get pods -n $namespace
Write-Host ""

Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
Write-Host ""

