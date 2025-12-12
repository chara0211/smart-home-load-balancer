# Script pour configurer l'Ingress et exposer les services automatiquement
# Cela évite d'avoir à utiliser port-forward manuellement

Write-Host "=== Configuration de l'Ingress pour Exposer les Services ===" -ForegroundColor Green
Write-Host ""

# 1. Activer l'Ingress Controller dans Minikube
Write-Host "1. Activation de l'Ingress Controller..." -ForegroundColor Yellow
minikube addons enable ingress

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'activation de l'Ingress" -ForegroundColor Red
    Write-Host "Essayez d'exécuter PowerShell en tant qu'administrateur" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Ingress Controller activé" -ForegroundColor Green
Write-Host ""

# Attendre que l'Ingress Controller soit prêt
Write-Host "Attente que l'Ingress Controller soit prêt..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 2. Appliquer l'Ingress
Write-Host "2. Application de l'Ingress..." -ForegroundColor Yellow
kubectl apply -f k8s/ingress/ingress.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'application de l'Ingress" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Ingress appliqué" -ForegroundColor Green
Write-Host ""

# 3. Attendre que l'Ingress obtienne une IP
Write-Host "3. Attente de l'attribution d'une IP..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $ingress = kubectl get ingress smarthome-ingress -n smarthome -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>&1
    if ($ingress -and $ingress -ne "") {
        break
    }
    Start-Sleep -Seconds 2
    $attempt++
    Write-Host "  Tentative $attempt/$maxAttempts..." -ForegroundColor Gray
}

# 4. Obtenir l'IP de Minikube
Write-Host ""
Write-Host "4. Récupération de l'IP Minikube..." -ForegroundColor Yellow
$minikubeIP = minikube ip

if (-not $minikubeIP) {
    Write-Host "❌ Impossible d'obtenir l'IP de Minikube" -ForegroundColor Red
    exit 1
}

Write-Host "✅ IP Minikube : $minikubeIP" -ForegroundColor Green
Write-Host ""

# 5. Afficher les instructions
Write-Host "=== CONFIGURATION TERMINÉE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Pour accéder aux services via Ingress :" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Ajoutez cette ligne dans C:\Windows\System32\drivers\etc\hosts :" -ForegroundColor Cyan
Write-Host "   (Ouvrez en tant qu'administrateur)" -ForegroundColor Gray
Write-Host ""
Write-Host "   $minikubeIP smarthome.local" -ForegroundColor White
Write-Host ""
Write-Host "2. Accédez aux services via :" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Usage Collector :" -ForegroundColor Yellow
Write-Host "   http://smarthome.local/usage/current" -ForegroundColor White
Write-Host "   http://smarthome.local/usage/history" -ForegroundColor White
Write-Host ""
Write-Host "   Optimizer :" -ForegroundColor Yellow
Write-Host "   http://smarthome.local/optimizer/health" -ForegroundColor White
Write-Host "   http://smarthome.local/optimizer/info" -ForegroundColor White
Write-Host ""
Write-Host "   Device Simulator :" -ForegroundColor Yellow
Write-Host "   http://smarthome.local/devices/devices" -ForegroundColor White
Write-Host ""
Write-Host "   RabbitMQ Management :" -ForegroundColor Yellow
Write-Host "   http://smarthome.local/rabbitmq" -ForegroundColor White
Write-Host ""
Write-Host "✅ Plus besoin de port-forward !" -ForegroundColor Green
Write-Host ""
Write-Host "Note : Si vous préférez toujours utiliser port-forward pour Postman," -ForegroundColor Gray
Write-Host "      c'est aussi possible. L'Ingress est une alternative." -ForegroundColor Gray

