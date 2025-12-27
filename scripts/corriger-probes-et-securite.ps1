# Script pour corriger les probes et la sécurité des services Spring Boot
# Usage: .\scripts\corriger-probes-et-securite.ps1

$namespace = "smarthome"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTION PROBES ET SÉCURITÉ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Ce script va :" -ForegroundColor Yellow
Write-Host "  1. Augmenter les timeouts des probes pour les services Spring Boot" -ForegroundColor White
Write-Host "  2. Ajuster les failure thresholds" -ForegroundColor White
Write-Host "  3. Redémarrer les déploiements" -ForegroundColor White
Write-Host ""

$services = @(
    "billing-service",
    "usage-collector-service",
    "peak-detector-service",
    "optimizer-service",
    "device-simulator-service"
)

foreach ($service in $services) {
    Write-Host "Correction de $service..." -ForegroundColor Yellow
    
    # Patch les probes pour augmenter les timeouts
    kubectl patch deployment $service -n $namespace --type='json' -p=@"
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/startupProbe/initialDelaySeconds",
    "value": 60
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/startupProbe/failureThreshold",
    "value": 60
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/readinessProbe/initialDelaySeconds",
    "value": 180
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/readinessProbe/failureThreshold",
    "value": 10
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/livenessProbe/initialDelaySeconds",
    "value": 300
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/livenessProbe/failureThreshold",
    "value": 10
  }
]
"@
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $service corrigé" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Erreur lors de la correction de $service" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Redémarrage des déploiements..." -ForegroundColor Yellow

foreach ($service in $services) {
    kubectl rollout restart deployment/$service -n $namespace
    Write-Host "✅ $service redémarré" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TERMINÉ" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Surveillez les pods :" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace -w" -ForegroundColor White
Write-Host ""
Write-Host "Les pods devraient maintenant :" -ForegroundColor Green
Write-Host "  - Démarrer en 3-4 minutes" -ForegroundColor White
Write-Host "  - Devenir Ready sans redémarrages constants" -ForegroundColor White
Write-Host "  - Rester stables" -ForegroundColor White
Write-Host ""

