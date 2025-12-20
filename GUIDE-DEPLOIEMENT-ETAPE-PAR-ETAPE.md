# Guide de Déploiement Étape par Étape - Kubernetes

Ce guide vous accompagne pour redéployer tous vos services sur Kubernetes depuis le début.

---

## 📋 ÉTAPE 1 : Démarrer Minikube

```powershell
# Démarrer Minikube
minikube start

# Vérifier que Minikube est en cours d'exécution
minikube status

# Obtenir l'IP de Minikube (vous en aurez besoin plus tard)
minikube ip
```

**Notez l'IP affichée**, vous en aurez besoin pour accéder aux services.

---

## 📦 ÉTAPE 2 : Créer le Namespace

```powershell
# Créer le namespace smarthome
kubectl apply -f k8s/namespaces/smarthome-namespace.yaml

# Vérifier que le namespace a été créé
kubectl get namespace smarthome
```

---

## 🔐 ÉTAPE 3 : Créer les Secrets

### 3.1 Secret pour PostgreSQL

```powershell
kubectl create secret generic postgres-secret `
  --from-literal=username=smarthome `
  --from-literal=password=smarthome `
  --from-literal=database=smarthome `
  -n smarthome
```

### 3.2 Secret pour Docker Hub (si vos images sont privées)

Si vos images Docker sont publiques sur Docker Hub, vous pouvez **ignorer cette étape**.

Si vos images sont privées, créez le secret :

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

### 3.3 Vérifier les secrets

```powershell
kubectl get secrets -n smarthome
```

---

## 🗄️ ÉTAPE 4 : Déployer PostgreSQL

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

**Attendez que le pod PostgreSQL soit en état `Running` avant de continuer.**

---

## 🐰 ÉTAPE 5 : Déployer RabbitMQ

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

**Attendez que le pod RabbitMQ soit en état `Running` avant de continuer.**

---

## ⚙️ ÉTAPE 6 : Déployer les Services Backend

Déployez les services backend dans l'ordre suivant :

### 6.1 Usage Collector Service

```powershell
# Déployer Usage Collector Service
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/usage-collector/service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=usage-collector-service
```

### 6.2 Device Simulator Service

```powershell
# Déployer Device Simulator Service
kubectl apply -f k8s/services/device-simulator/deployment.yaml
kubectl apply -f k8s/services/device-simulator/service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=device-simulator-service
```

### 6.3 Peak Detector Service

```powershell
# Déployer Peak Detector Service
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=peak-detector-service
```

### 6.4 Optimizer Service

```powershell
# Déployer Optimizer Service
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/optimizer/service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=optimizer-service
```

### 6.5 Billing Service

```powershell
# Déployer Billing Service
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/billing/service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=billing-service
```

**Note** : Les services peuvent prendre quelques minutes pour démarrer. Vérifiez leur état avec :
```powershell
kubectl get pods -n smarthome
```

---

## 🎨 ÉTAPE 7 : Déployer le Frontend

```powershell
# Déployer le Frontend
kubectl apply -f k8s/services/frontend/deployment.yaml
kubectl apply -f k8s/services/frontend/service.yaml

# (Optionnel) Déployer aussi le service NodePort pour accès externe
kubectl apply -f k8s/services/frontend/service-nodeport.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=frontend
```

---

## 🔍 ÉTAPE 8 : Vérifier le Déploiement

### 8.1 Voir tous les pods

```powershell
kubectl get pods -n smarthome
```

Tous les pods devraient être en état `Running` après quelques minutes.

### 8.2 Voir tous les services

```powershell
kubectl get services -n smarthome
```

### 8.3 Voir les logs d'un service (si problème)

```powershell
# Exemple pour le frontend
kubectl logs -f deployment/frontend -n smarthome

# Exemple pour usage-collector-service
kubectl logs -f deployment/usage-collector-service -n smarthome
```

---

## 🌐 ÉTAPE 9 : Accéder au Frontend

### Méthode 1 : Port-Forward (Le Plus Simple)

```powershell
# Dans un terminal PowerShell, exécutez :
kubectl port-forward service/frontend-service 3000:3000 -n smarthome
```

**Gardez ce terminal ouvert**, puis ouvrez votre navigateur sur : **http://localhost:3000**

### Méthode 2 : Via NodePort

```powershell
# Obtenir l'IP de Minikube
minikube ip
```

Puis ouvrez dans votre navigateur : **http://<IP>:30000**

(Remplacez `<IP>` par l'IP obtenue avec `minikube ip`)

---

## 🐛 Dépannage

### Un pod est en état "ImagePullBackOff"

Cela signifie que Kubernetes ne peut pas télécharger l'image. Vérifiez :

1. **L'image existe sur Docker Hub** :
   ```powershell
   docker pull salmaidoufkir/usage-collector-service:latest
   ```

2. **Le secret registry-secret existe** (si l'image est privée) :
   ```powershell
   kubectl get secret registry-secret -n smarthome
   ```

3. **L'image est publique** : Si l'image est publique, vous n'avez pas besoin du secret.

### Un pod est en état "Pending"

Cela peut être dû à un manque de ressources. Vérifiez :

```powershell
# Voir les détails du pod
kubectl describe pod <nom-du-pod> -n smarthome

# Voir les ressources disponibles
kubectl top nodes
```

### Un service ne démarre pas

Vérifiez les logs :

```powershell
kubectl logs -f deployment/<nom-du-service> -n smarthome
```

### Redémarrer un service

```powershell
kubectl rollout restart deployment/<nom-du-service> -n smarthome
```

---

## 📝 Commandes Utiles

### Voir l'état de tous les composants

```powershell
# Tous les pods
kubectl get pods -n smarthome

# Tous les services
kubectl get services -n smarthome

# Tous les deployments
kubectl get deployments -n smarthome

# Tout en une fois
kubectl get all -n smarthome
```

### Supprimer un service (si besoin de redéployer)

```powershell
# Supprimer un deployment
kubectl delete deployment <nom-du-service> -n smarthome

# Supprimer un service
kubectl delete service <nom-du-service> -n smarthome
```

### Voir les événements (pour déboguer)

```powershell
kubectl get events -n smarthome --sort-by='.lastTimestamp'
```

---

## ✅ Checklist de Vérification

Après le déploiement, vérifiez que :

- [ ] Minikube est en cours d'exécution
- [ ] Le namespace `smarthome` existe
- [ ] Les secrets sont créés (postgres-secret, et registry-secret si nécessaire)
- [ ] PostgreSQL est en état `Running`
- [ ] RabbitMQ est en état `Running`
- [ ] Tous les services backend sont en état `Running`
- [ ] Le frontend est en état `Running`
- [ ] Vous pouvez accéder au frontend via port-forward ou NodePort

---

## 🎯 Prochaines Étapes

Une fois tout déployé :

1. **Tester le frontend** : Accédez à http://localhost:3000 (via port-forward)
2. **Vérifier les logs** : Surveillez les logs des services pour détecter d'éventuelles erreurs
3. **Configurer l'Ingress** (optionnel) : Pour un accès permanent via un domaine

---

**Bon déploiement ! 🚀**

