# Guide : Redéploiement Complet Après minikube delete

Ce guide vous accompagne pour redéployer tous vos services depuis le début après avoir supprimé Minikube.

## ✅ Étape 1 : Namespace Créé

Le namespace `smarthome` a été créé avec succès.

## 🔐 Étape 2 : Créer les Secrets

### 2.1 Secret PostgreSQL

```powershell
kubectl create secret generic postgres-secret `
  --from-literal=username=smarthome `
  --from-literal=password=smarthome `
  --from-literal=database=smarthome `
  -n smarthome
```

### 2.2 Secret RabbitMQ

```powershell
kubectl create secret generic rabbitmq-secret `
  --from-literal=username=guest `
  --from-literal=password=guest `
  -n smarthome
```

### 2.3 Secret Docker Hub (Si vos images sont privées)

Si vos images Docker sont **publiques**, vous pouvez **ignorer cette étape**.

Si vos images sont **privées**, créez le secret :

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=https://index.docker.io/v1/ `
  --docker-username=VOTRE_USERNAME_DOCKER_HUB `
  --docker-password=VOTRE_PASSWORD_DOCKER_HUB `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

**Remplacez** :
- `VOTRE_USERNAME_DOCKER_HUB` : Votre nom d'utilisateur Docker Hub
- `VOTRE_PASSWORD_DOCKER_HUB` : Votre mot de passe Docker Hub
- `VOTRE_EMAIL` : Votre email

### 2.4 Vérifier les secrets

```powershell
kubectl get secrets -n smarthome
```

Vous devriez voir au minimum :
- `postgres-secret`
- `rabbitmq-secret`
- `registry-secret` (si vous l'avez créé)

---

## 🗄️ Étape 3 : Déployer PostgreSQL

```powershell
# Déployer PostgreSQL
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

# Vérifier que PostgreSQL démarre
kubectl get pods -n smarthome -l app=postgres

# Attendre que le pod soit en état "Running" (peut prendre 1-2 minutes)
kubectl wait --for=condition=ready pod -l app=postgres -n smarthome --timeout=300s

# Vérifier les logs si nécessaire
kubectl logs -f deployment/postgres -n smarthome
```

**⚠️ Important** : Attendez que PostgreSQL soit complètement prêt (`Running` et `Ready 1/1`) avant de continuer.

---

## 🐰 Étape 4 : Déployer RabbitMQ

```powershell
# Déployer RabbitMQ
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml

# Vérifier que RabbitMQ démarre
kubectl get pods -n smarthome -l app=rabbitmq

# Attendre que le pod soit en état "Running" (peut prendre 1-2 minutes)
kubectl wait --for=condition=ready pod -l app=rabbitmq -n smarthome --timeout=300s

# Vérifier les logs si nécessaire
kubectl logs -f deployment/rabbitmq -n smarthome
```

**⚠️ Important** : Attendez que RabbitMQ soit complètement prêt avant de continuer.

---

## ⚙️ Étape 5 : Déployer les Services Backend

Déployez les services dans l'ordre suivant :

### 5.1 Usage Collector Service

```powershell
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/usage-collector/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=usage-collector-service
```

### 5.2 Device Simulator Service

```powershell
kubectl apply -f k8s/services/device-simulator/deployment.yaml
kubectl apply -f k8s/services/device-simulator/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=device-simulator-service
```

### 5.3 Peak Detector Service

```powershell
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=peak-detector-service
```

### 5.4 Optimizer Service

```powershell
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/optimizer/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=optimizer-service
```

### 5.5 Billing Service

```powershell
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/billing/service.yaml

# Vérifier
kubectl get pods -n smarthome -l app=billing-service
```

---

## 🎨 Étape 6 : Déployer le Frontend

```powershell
# Déployer le Frontend
kubectl apply -f k8s/services/frontend/deployment.yaml
kubectl apply -f k8s/services/frontend/service.yaml

# (Optionnel) Déployer aussi le service NodePort pour accès externe
kubectl apply -f k8s/services/frontend/service-nodeport.yaml

# Vérifier
kubectl get pods -n smarthome -l app=frontend
```

---

## 🔍 Étape 7 : Vérification Complète

```powershell
# Voir tous les pods
kubectl get pods -n smarthome

# Voir tous les services
kubectl get services -n smarthome

# Voir tous les deployments
kubectl get deployments -n smarthome

# Voir tout en une fois
kubectl get all -n smarthome
```

Tous les pods devraient être en état `Running` et `Ready` (1/1) après quelques minutes.

---

## 🐛 Dépannage

### Si un service est en ImagePullBackOff

Cela signifie que Minikube ne peut pas télécharger l'image depuis Docker Hub. Vérifiez :

1. **Minikube peut accéder à Docker Hub** :
   ```powershell
   minikube ssh "docker pull hello-world"
   ```

2. **L'image existe sur Docker Hub** :
   ```powershell
   docker pull salmaidoufkir/usage-collector-service:latest
   ```

3. **Le secret registry-secret existe** (si l'image est privée) :
   ```powershell
   kubectl get secret registry-secret -n smarthome
   ```

**Solution** : Voir `SOLUTION-MINIKUBE-ACCES-DOCKER-HUB.md`

### Si un service est en CrashLoopBackOff

```powershell
# Voir les logs
kubectl logs -f deployment/<service-name> -n smarthome

# Voir les détails du pod
kubectl describe pod -l app=<service-name> -n smarthome
```

### Si un service ne peut pas se connecter à PostgreSQL ou RabbitMQ

Vérifiez que les services de base sont prêts :

```powershell
# Vérifier PostgreSQL
kubectl get pods -n smarthome -l app=postgres

# Vérifier RabbitMQ
kubectl get pods -n smarthome -l app=rabbitmq

# Tester la connexion
kubectl exec -it deployment/<service-name> -n smarthome -- ping postgres-service
```

---

## 📝 Checklist de Déploiement

- [ ] Namespace `smarthome` créé
- [ ] Secret `postgres-secret` créé
- [ ] Secret `rabbitmq-secret` créé
- [ ] Secret `registry-secret` créé (si nécessaire)
- [ ] PostgreSQL déployé et Running
- [ ] RabbitMQ déployé et Running
- [ ] Usage Collector Service déployé et Running
- [ ] Device Simulator Service déployé et Running
- [ ] Peak Detector Service déployé et Running
- [ ] Optimizer Service déployé et Running
- [ ] Billing Service déployé et Running
- [ ] Frontend déployé et Running

---

## 🚀 Commandes Rapides (Tout en Une Fois)

Une fois les secrets créés, vous pouvez déployer tout en une fois :

```powershell
# Bases de données
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

# Message broker
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml

# Attendre que PostgreSQL et RabbitMQ soient prêts
kubectl wait --for=condition=ready pod -l app=postgres -n smarthome --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n smarthome --timeout=300s

# Services backend
kubectl apply -f k8s/services/usage-collector/
kubectl apply -f k8s/services/device-simulator/
kubectl apply -f k8s/services/peak-detector/
kubectl apply -f k8s/services/optimizer/
kubectl apply -f k8s/services/billing/

# Frontend
kubectl apply -f k8s/services/frontend/

# Vérifier tout
kubectl get all -n smarthome
```

---

**Bon redéploiement ! 🚀**

