# Guide : Tester Kubernetes - Ce qu'il Faut Avant de Commencer

Ce document explique **ce qui est déjà prêt**, **ce qui manque**, et **comment tester Kubernetes** pour ce projet.

---

## ✅ Ce qui est Déjà Prêt

### 1. Fichiers de Configuration Kubernetes

Tous les manifests Kubernetes sont créés et prêts :

- ✅ **Namespace** : `k8s/namespaces/smarthome-namespace.yaml`
- ✅ **Deployments** : Tous les services (usage-collector, peak-detector, device-simulator, optimizer)
- ✅ **Services** : Load balancers internes pour chaque microservice
- ✅ **HPA** : Auto-scaling configuré
- ✅ **Bases de données** : PostgreSQL, MongoDB, Cassandra
- ✅ **Message broker** : RabbitMQ
- ✅ **API Gateway** : NGINX
- ✅ **Monitoring** : Prometheus, Grafana, Elastic Stack
- ✅ **Keycloak** : Authentification
- ✅ **Ingress** : Point d'entrée externe
- ✅ **Script de déploiement** : `scripts/deploy-all.sh`

---

## ❌ Ce qui Manque AVANT de Tester

### 1. Cluster Kubernetes

**Vous devez avoir un cluster Kubernetes en cours d'exécution.**

#### Option A : Cluster Local (Recommandé pour tester)

**Minikube** (le plus simple pour Windows) :
```bash
# Installer Minikube
# Télécharger depuis : https://minikube.sigs.k8s.io/docs/start/

# Démarrer Minikube
minikube start

# Vérifier
kubectl get nodes
```

**Kind (Kubernetes in Docker)** :
```bash
# Installer Kind
# Télécharger depuis : https://kind.sigs.k8s.io/docs/user/quick-start/

# Créer un cluster
kind create cluster --name smarthome

# Vérifier
kubectl get nodes
```

**Docker Desktop (si vous avez la version avec Kubernetes)** :
- Activer Kubernetes dans les paramètres de Docker Desktop
- Vérifier : `kubectl get nodes`

#### Option B : Cluster Cloud

- **Google Cloud (GKE)**
- **Amazon (EKS)**
- **Azure (AKS)**
- **DigitalOcean**

### 2. Outil kubectl

**Vous devez installer `kubectl`** (client Kubernetes) :

```bash
# Windows (via Chocolatey)
choco install kubernetes-cli

# Ou télécharger depuis : https://kubernetes.io/docs/tasks/tools/

# Vérifier l'installation
kubectl version --client
```

### 3. Images Docker des Microservices

**Problème actuel** : Les deployments pointent vers des images qui n'existent pas encore :

```24:24:k8s/services/usage-collector/deployment.yaml
        image: salmaidoufkir/usage-collector-service:latest
```

**Solutions** :

#### Option A : Utiliser les Images Locales (Minikube/Kind)

1. **Construire les images Docker localement** :
```bash
# Construire chaque service
cd usage-collector-service
docker build -t usage-collector-service:latest .

cd ../peak-detector-service
docker build -t peak-detector-service:latest .

cd ../device-simulator-service
docker build -t device-simulator-service:latest .

cd ../optimizer-service
docker build -t optimizer-service:latest .
```

2. **Charger les images dans Minikube** :
```bash
# Minikube utilise son propre Docker daemon
minikube image load usage-collector-service:latest
minikube image load peak-detector-service:latest
minikube image load device-simulator-service:latest
minikube image load optimizer-service:latest
```

3. **Modifier les deployments** pour utiliser les images locales :
   - Remplacer `salmaidoufkir/usage-collector-service:latest` par `usage-collector-service:latest`
   - Remplacer `imagePullPolicy: Always` par `imagePullPolicy: Never` ou `IfNotPresent`

#### Option B : Utiliser un Registry Docker

1. **Pousser les images vers un registry** (Docker Hub, GitHub Container Registry, etc.) :
```bash
# Tag les images
docker tag usage-collector-service:latest votre-username/usage-collector-service:latest

# Push vers Docker Hub
docker push votre-username/usage-collector-service:latest
```

2. **Mettre à jour les deployments** avec le bon nom d'image

3. **Créer le secret pour le registry** (si privé) :
```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=docker.io \
  --docker-username=votre-username \
  --docker-password=votre-password \
  -n smarthome
```

### 4. Secrets Kubernetes

**Les secrets doivent être créés manuellement** avant le déploiement :

```bash
# Créer le namespace d'abord
kubectl apply -f k8s/namespaces/

# Créer les secrets
kubectl create secret generic postgres-secret --from-literal=username=smarthome --from-literal=password=smarthome --from-literal=database=smarthome -n smarthome

kubectl create secret generic rabbitmq-secret --from-literal=username=guest --from-literal=password=guest -n smarthome

kubectl create secret generic mongodb-secret \
  --from-literal=username=admin \
  --from-literal=password=admin123 \
  -n smarthome

kubectl create secret generic keycloak-secret \
  --from-literal=username=admin \
  --from-literal=password=admin123 \
  -n smarthome

kubectl create secret generic grafana-secret \
  --from-literal=password=admin123 \
  -n smarthome
```

**Voir** : `k8s/secrets/README.md` pour plus de détails.

### 5. Ingress Controller (Optionnel)

Si vous voulez utiliser l'Ingress, vous devez installer un Ingress Controller :

**Pour Minikube** :
```bash
minikube addons enable ingress
```

**Pour Kind** :
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

---

## 🧪 Checklist Avant de Tester

Avant de pouvoir tester Kubernetes, vérifiez que vous avez :

- [ ] **Cluster Kubernetes** en cours d'exécution (`kubectl get nodes` doit fonctionner)
- [ ] **kubectl** installé et configuré (`kubectl version --client`)
- [ ] **Images Docker** construites et disponibles (localement ou dans un registry)
- [ ] **Secrets Kubernetes** créés (voir section ci-dessus)
- [ ] **Deployments modifiés** pour pointer vers les bonnes images (si vous utilisez des images locales)

---

## 🚀 Étapes pour Tester (Ordre Recommandé)

### Étape 1 : Préparer l'Environnement

```bash
# 1. Vérifier que Kubernetes fonctionne
kubectl get nodes

# 2. Créer le namespace
kubectl apply -f k8s/namespaces/

# 3. Créer les secrets
# (voir section "Secrets Kubernetes" ci-dessus)
```

### Étape 2 : Tester avec les Bases de Données Seulement

**Commencez petit** pour vérifier que tout fonctionne :

```bash
# Déployer PostgreSQL
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

# Vérifier
kubectl get pods -n smarthome
kubectl get services -n smarthome

# Voir les logs
kubectl logs -f deployment/postgres -n smarthome
```

### Étape 3 : Tester avec RabbitMQ

```bash
# Déployer RabbitMQ
kubectl apply -f k8s/message-broker/

# Vérifier
kubectl get pods -n smarthome
kubectl wait --for=condition=ready pod -l app=rabbitmq -n smarthome --timeout=300s
kubectl logs -f deployment/rabbitmq -n smarthome

```

### Étape 4 : Tester un Microservice

**Important** : Modifiez d'abord le deployment pour utiliser la bonne image !

```bash
# Exemple : Usage Collector Service
# 1. Modifier k8s/services/usage-collector/deployment.yaml
#    - Changer l'image
#    - Changer imagePullPolicy si nécessaire

# 2. Déployer
kubectl apply -f k8s/services/usage-collector/

# 3. Vérifier
kubectl get pods -n smarthome
kubectl logs -f deployment/usage-collector-service -n smarthome

# 4. Tester la connexion
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome
# Puis ouvrir http://localhost:8083/actuator/health
```

### Étape 5 : Déployer Tout (Optionnel)

Une fois que vous avez testé les composants individuellement :

```bash
# Utiliser le script de déploiement
./scripts/deploy-all.sh

# Ou déployer manuellement dans l'ordre :
# 1. Namespace et secrets (déjà fait)
# 2. Bases de données
kubectl apply -f k8s/databases/
# 3. Message broker
kubectl apply -f k8s/message-broker/
# 4. Microservices
kubectl apply -f k8s/services/
# 5. API Gateway
kubectl apply -f k8s/api-gateway/
```

---

## 🔧 Configuration Rapide pour Tester Localement

### Solution la Plus Simple : Minikube + Images Locales

1. **Installer Minikube** :
   - Télécharger depuis https://minikube.sigs.k8s.io/docs/start/
   - Ou via Chocolatey : `choco install minikube`

2. **Démarrer Minikube** :
```bash
minikube start
```

3. **Construire les images** :
```bash
# Dans chaque dossier de service
docker build -t usage-collector-service:latest ./usage-collector-service
docker build -t peak-detector-service:latest ./peak-detector-service
docker build -t device-simulator-service:latest ./device-simulator-service
docker build -t optimizer-service:latest ./optimizer-service
```

4. **Charger dans Minikube** :
```bash
minikube image load usage-collector-service:latest
minikube image load peak-detector-service:latest
minikube image load device-simulator-service:latest
minikube image load optimizer-service:latest
```

5. **Modifier les deployments** :
   - Ouvrir `k8s/services/*/deployment.yaml`
   - Remplacer `salmaidoufkir/usage-collector-service:latest` par `usage-collector-service:latest`
   - Remplacer `imagePullPolicy: Always` par `imagePullPolicy: Never`

6. **Créer les secrets** (voir section ci-dessus)

7. **Déployer** :
```bash
kubectl apply -f k8s/namespaces/
kubectl apply -f k8s/databases/
kubectl apply -f k8s/message-broker/
kubectl apply -f k8s/services/usage-collector/
```

---

## 🐛 Problèmes Courants

### Erreur : "ImagePullBackOff"

**Cause** : Kubernetes ne peut pas télécharger l'image.

**Solutions** :
- Vérifier que l'image existe localement (Minikube) ou dans le registry
- Vérifier le nom de l'image dans le deployment
- Changer `imagePullPolicy: Always` en `imagePullPolicy: Never` pour les images locales

### Erreur : "CrashLoopBackOff"

**Cause** : Le pod démarre mais crash immédiatement.

**Solutions** :
```bash
# Voir les logs
kubectl logs -f deployment/usage-collector-service -n smarthome

# Voir les événements
kubectl describe pod <pod-name> -n smarthome
```

**Causes fréquentes** :
- Base de données pas encore prête (vérifier les dépendances)
- Variables d'environnement manquantes
- Erreur de connexion à PostgreSQL/RabbitMQ

### Erreur : "Pending"

**Cause** : Le pod ne peut pas être planifié.

**Solutions** :
```bash
# Voir pourquoi
kubectl describe pod <pod-name> -n smarthome

# Causes fréquentes :
# - Pas assez de ressources (CPU/mémoire)
# - PVC (PersistentVolumeClaim) en attente
```

---

## 📊 Commandes Utiles pour Tester

```bash
# Voir tous les pods
kubectl get pods -n smarthome

# Voir les services
kubectl get services -n smarthome

# Voir les logs d'un pod
kubectl logs -f deployment/usage-collector-service -n smarthome

# Accéder à un service localement (port-forward)
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome

# Voir les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp'

# Décrire un pod (diagnostic)
kubectl describe pod <pod-name> -n smarthome

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -n smarthome -- /bin/bash

# Supprimer un déploiement
kubectl delete deployment/usage-collector-service -n smarthome

# Voir les ressources utilisées
kubectl top pods -n smarthome
```

---

## ✅ Résumé : Ce qu'il Faut Faire

### Minimum pour Tester (Ordre de Priorité)

1. **Installer kubectl** ✅ Facile
2. **Installer Minikube** (ou utiliser Docker Desktop Kubernetes) ✅ Facile
3. **Construire les images Docker** ✅ Facile (déjà des Dockerfiles)
4. **Modifier les deployments** pour utiliser les images locales ⚠️ Nécessite de modifier les fichiers YAML
5. **Créer les secrets** ✅ Facile (commandes kubectl)

### Ce qui Peut Attendre

- Ingress Controller (pour exposer les services)
- Monitoring (Prometheus, Grafana)
- Keycloak (authentification)
- API Gateway (NGINX)
- Bases de données supplémentaires (MongoDB, Cassandra)

**Recommandation** : Commencez par tester avec PostgreSQL + RabbitMQ + 1 microservice, puis ajoutez le reste progressivement.

---

## 🎯 Conclusion

**Vous pouvez tester Kubernetes MAIS** vous devez d'abord :

1. ✅ Installer kubectl et un cluster Kubernetes (Minikube recommandé)
2. ✅ Construire les images Docker des microservices
3. ⚠️ Modifier les deployments pour pointer vers les bonnes images
4. ✅ Créer les secrets Kubernetes

**Temps estimé** : 30-60 minutes pour tout configurer la première fois.

Une fois configuré, vous pourrez tester et voir Kubernetes en action ! 🚀

