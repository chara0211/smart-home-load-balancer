# Script pour exposer les services via NodePort (alternative à Ingress)
# Plus simple que Ingress, fonctionne immédiatement

Write-Host "=== Exposition des Services via NodePort ===" -ForegroundColor Green
Write-Host ""

# Obtenir l'IP de Minikube
$minikubeIP = minikube ip
if (-not $minikubeIP) {
    Write-Host "❌ Impossible d'obtenir l'IP de Minikube" -ForegroundColor Red
    exit 1
}

Write-Host "IP Minikube : $minikubeIP" -ForegroundColor Cyan
Write-Host ""

# Créer des services NodePort pour chaque microservice
Write-Host "Création des services NodePort..." -ForegroundColor Yellow

# Usage Collector Service
Write-Host "  → Usage Collector Service (NodePort 30083)" -ForegroundColor Cyan
$usageCollectorNodePort = @"
apiVersion: v1
kind: Service
metadata:
  name: usage-collector-service-nodeport
  namespace: smarthome
  labels:
    app: usage-collector-service
spec:
  type: NodePort
  ports:
  - port: 8083
    targetPort: 8083
    nodePort: 30083
    protocol: TCP
    name: http
  selector:
    app: usage-collector-service
"@
$usageCollectorNodePort | kubectl apply -f -

# Peak Detector Service
Write-Host "  → Peak Detector Service (NodePort 30084)" -ForegroundColor Cyan
$peakDetectorNodePort = @"
apiVersion: v1
kind: Service
metadata:
  name: peak-detector-service-nodeport
  namespace: smarthome
  labels:
    app: peak-detector-service
spec:
  type: NodePort
  ports:
  - port: 8084
    targetPort: 8084
    nodePort: 30084
    protocol: TCP
    name: http
  selector:
    app: peak-detector-service
"@
$peakDetectorNodePort | kubectl apply -f -

# Optimizer Service
Write-Host "  → Optimizer Service (NodePort 30085)" -ForegroundColor Cyan
$optimizerNodePort = @"
apiVersion: v1
kind: Service
metadata:
  name: optimizer-service-nodeport
  namespace: smarthome
  labels:
    app: optimizer-service
spec:
  type: NodePort
  ports:
  - port: 8085
    targetPort: 8085
    nodePort: 30085
    protocol: TCP
    name: http
  selector:
    app: optimizer-service
"@
$optimizerNodePort | kubectl apply -f -

# Device Simulator Service
Write-Host "  → Device Simulator Service (NodePort 30082)" -ForegroundColor Cyan
$deviceSimNodePort = @"
apiVersion: v1
kind: Service
metadata:
  name: device-simulator-service-nodeport
  namespace: smarthome
  labels:
    app: device-simulator-service
spec:
  type: NodePort
  ports:
  - port: 8082
    targetPort: 8082
    nodePort: 30082
    protocol: TCP
    name: http
  selector:
    app: device-simulator-service
"@
$deviceSimNodePort | kubectl apply -f -

Write-Host ""
Write-Host "✅ Services NodePort créés !" -ForegroundColor Green
Write-Host ""
Write-Host "=== ACCÈS AUX SERVICES ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vous pouvez maintenant accéder aux services depuis Postman :" -ForegroundColor Yellow
Write-Host ""
Write-Host "Usage Collector Service :" -ForegroundColor Yellow
Write-Host "  http://$minikubeIP`:30083/usage/current" -ForegroundColor White
Write-Host "  http://$minikubeIP`:30083/actuator/health" -ForegroundColor White
Write-Host ""
Write-Host "Peak Detector Service :" -ForegroundColor Yellow
Write-Host "  http://$minikubeIP`:30084/actuator/health" -ForegroundColor White
Write-Host ""
Write-Host "Optimizer Service :" -ForegroundColor Yellow
Write-Host "  http://$minikubeIP`:30085/optimizer/health" -ForegroundColor White
Write-Host "  http://$minikubeIP`:30085/optimizer/info" -ForegroundColor White
Write-Host ""
Write-Host "Device Simulator Service :" -ForegroundColor Yellow
Write-Host "  http://$minikubeIP`:30082/devices" -ForegroundColor White
Write-Host "  http://$minikubeIP`:30082/actuator/health" -ForegroundColor White
Write-Host ""
Write-Host "✅ Plus besoin de port-forward !" -ForegroundColor Green
Write-Host ""
Write-Host "Note : Les services ClusterIP originaux restent pour la communication interne" -ForegroundColor Gray
Write-Host "      Les services NodePort sont en plus pour l'accès externe" -ForegroundColor Gray

