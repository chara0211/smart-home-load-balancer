# Guide : Déployer Tous les Services Restants

## 🔴 État Actuel

- ✅ **RabbitMQ** : Fonctionne
- ✅ **Device Simulator Service** : Fonctionne
- ❌ **PostgreSQL** : ImagePullBackOff (problème d'accès Docker Hub)
- ❌ **Usage Collector Service** : CrashLoopBackOff (ne peut pas se connecter à PostgreSQL)
- ⏳ **Services non déployés** : Peak Detector, Optimizer, Billing, Frontend

## 📋 Plan d'Action

### Étape 1 : Résoudre le Problème d'Accès à Docker Hub

Avant de continuer, vous devez résoudre le problème d'accès à Docker Hub. Choisissez une solution :

#### Option A : Utiliser le Driver Docker (Recommandé)

```powershell
# Arrêter Minikube
minikube stop
minikube delete

# Redémarrer avec Docker driver
minikube start --driver=docker

# Tester l'accès à Docker Hub
minikube ssh "docker pull postgres:16"
```

#### Option B : Configurer le Proxy (Si vous êtes derrière un proxy)

```powershell
# Arrêter Minikube
minikube stop

# Configurer le proxy (remplacez par vos valeurs)
$env:HTTP_PROXY="http://votre-proxy:port"
$env:HTTPS_PROXY="http://votre-proxy:port"

# Redémarrer avec proxy
minikube start --docker-env HTTP_PROXY=$env:HTTP_PROXY --docker-env HTTPS_PROXY=$env:HTTPS_PROXY
```

**Voir le guide complet** : `SOLUTION-MINIKUBE-ACCES-DOCKER-HUB.md`

---

### Étape 2 : Corriger PostgreSQL

Une fois que Minikube peut accéder à Docker Hub :

```powershell
# Supprimer le deployment et le PVC corrompu
kubectl delete deployment postgres -n smarthome
kubectl delete pvc postgres-pvc -n smarthome

# Redéployer PostgreSQL
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

# Attendre que PostgreSQL soit prêt
kubectl wait --for=condition=ready pod -l app=postgres -n smarthome --timeout=300s

# Vérifier
kubectl get pods -n smarthome -l app=postgres
```

---

### Étape 3 : Redémarrer Usage Collector Service

Une fois PostgreSQL fonctionnel :

```powershell
# Redémarrer le deployment
kubectl rollout restart deployment/usage-collector-service -n smarthome

# Vérifier qu'il démarre correctement
kubectl get pods -n smarthome -l app=usage-collector-service

# Voir les logs
kubectl logs -f deployment/usage-collector-service -n smarthome
```

---

### Étape 4 : Déployer Peak Detector Service

```powershell
# Vérifier que l'image existe localement
docker images | Select-String "peak-detector"

# Si l'image n'existe pas, la builder et pusher
cd peak-detector-service
docker build -t salmaidoufkir/peak-detector-service:latest .
docker push salmaidoufkir/peak-detector-service:latest
cd ..

# Déployer
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=peak-detector-service
```

---

### Étape 5 : Déployer Optimizer Service

```powershell
# Vérifier que l'image existe localement
docker images | Select-String "optimizer"

# Si l'image n'existe pas, la builder et pusher
cd optimizer-service
docker build -t salmaidoufkir/optimizer-service:latest .
docker push salmaidoufkir/optimizer-service:latest
cd ..

# Déployer
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/optimizer/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=optimizer-service
```

---

### Étape 6 : Déployer Billing Service

```powershell
# Vérifier que l'image existe localement
docker images | Select-String "billing"

# Si l'image n'existe pas, la builder et pusher
cd billing-service
docker build -t salmaidoufkir/billing-service:latest .
docker push salmaidoufkir/billing-service:latest
cd ..

# Déployer
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/billing/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=billing-service
```

---

### Étape 7 : Déployer le Frontend

```powershell
# Vérifier que l'image existe localement
docker images | Select-String "frontend"

# Si l'image n'existe pas, la builder et pusher
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest
cd ..

# Déployer
kubectl apply -f k8s/services/frontend/deployment.yaml
kubectl apply -f k8s/services/frontend/service.yaml

# (Optionnel) Déployer aussi le service NodePort
kubectl apply -f k8s/services/frontend/service-nodeport.yaml

# Vérifier
kubectl get pods -n smarthome -l app=frontend
```

---

## 🔍 Vérification Finale

Une fois tous les services déployés :

```powershell
# Voir tous les pods
kubectl get pods -n smarthome

# Voir tous les services
kubectl get services -n smarthome

# Voir tous les deployments
kubectl get deployments -n smarthome
```

Tous les pods devraient être en état `Running` et `Ready` (1/1).

---

## 🐛 Dépannage

### Si un service est en ImagePullBackOff

1. Vérifier que l'image existe sur Docker Hub
2. Vérifier que Minikube peut accéder à Docker Hub
3. Vérifier que le secret `registry-secret` existe (si l'image est privée)

### Si un service est en CrashLoopBackOff

```powershell
# Voir les logs
kubectl logs -f deployment/<service-name> -n smarthome

# Voir les détails du pod
kubectl describe pod -l app=<service-name> -n smarthome
```

### Si un service ne peut pas se connecter à PostgreSQL ou RabbitMQ

Vérifier que les services de base sont prêts :

```powershell
# Vérifier PostgreSQL
kubectl get pods -n smarthome -l app=postgres

# Vérifier RabbitMQ
kubectl get pods -n smarthome -l app=rabbitmq

# Tester la connexion depuis un pod
kubectl exec -it deployment/<service-name> -n smarthome -- ping postgres-service
```

---

## 📝 Checklist

- [ ] Minikube peut accéder à Docker Hub
- [ ] PostgreSQL est en état Running
- [ ] RabbitMQ est en état Running
- [ ] Usage Collector Service est en état Running
- [ ] Device Simulator Service est en état Running
- [ ] Peak Detector Service est déployé et Running
- [ ] Optimizer Service est déployé et Running
- [ ] Billing Service est déployé et Running
- [ ] Frontend est déployé et Running

---

## 🚀 Commandes Rapides pour Déployer Tous les Services

Une fois que Minikube peut accéder à Docker Hub, vous pouvez déployer tous les services restants en une fois :

```powershell
# Peak Detector
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/service.yaml

# Optimizer
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/optimizer/service.yaml

# Billing
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/billing/service.yaml

# Frontend
kubectl apply -f k8s/services/frontend/deployment.yaml
kubectl apply -f k8s/services/frontend/service.yaml
kubectl apply -f k8s/services/frontend/service-nodeport.yaml

# Vérifier tout
kubectl get all -n smarthome
```

---

**Bon déploiement ! 🚀**

