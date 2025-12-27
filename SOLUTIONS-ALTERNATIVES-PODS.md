# Solutions Alternatives pour les Pods Non Prêts

## 🔴 Problème Actuel

- **PostgreSQL** : CrashLoopBackOff (59 redémarrages) - **PROBLÈME CRITIQUE**
- **Tous les services** : Running mais 0/1 Ready
- **RabbitMQ** : Running mais 0/1 Ready
- **Ressources limitées** : Cluster Minikube saturé

## ✅ Solution Alternative 1 : Utiliser Docker Compose (RECOMMANDÉ pour le développement)

### Avantages
- ✅ Plus simple à gérer
- ✅ Moins de ressources nécessaires
- ✅ Démarrage plus rapide
- ✅ Pas de problèmes de scheduling Kubernetes
- ✅ Idéal pour le développement local

### Migration vers Docker Compose

Vous avez déjà un `docker-compose.yml`. Utilisez-le :

```powershell
# Arrêter Minikube
minikube stop

# Démarrer avec Docker Compose
docker-compose up -d

# Vérifier l'état
docker-compose ps
```

### Configuration Docker Compose

Votre `docker-compose.yml` existe déjà. Vous pouvez :
1. L'utiliser directement pour le développement
2. Garder Kubernetes pour la production
3. Utiliser les deux selon le contexte

## ✅ Solution Alternative 2 : Réinitialiser PostgreSQL

PostgreSQL crash constamment. Solution radicale :

### Option A : Supprimer et Recréer PostgreSQL

```powershell
# ⚠️ ATTENTION : Cela supprimera toutes les données PostgreSQL !
kubectl delete deployment postgres -n smarthome
kubectl delete pvc postgres-pvc -n smarthome

# Recréer PostgreSQL
kubectl apply -f k8s/databases/postgres-deployment.yaml

# Attendre que PostgreSQL soit prêt
kubectl wait --for=condition=ready pod -n smarthome -l app=postgres --timeout=300s
```

### Option B : Utiliser PostgreSQL Externe

Utiliser une base de données PostgreSQL externe (cloud ou locale) :

```powershell
# Modifier les variables d'environnement des services pour pointer vers PostgreSQL externe
# Au lieu de : postgres-service:5432
# Utiliser : votre-postgres-externe:5432
```

## ✅ Solution Alternative 3 : Architecture Simplifiée

Désactiver temporairement les services non essentiels :

### Script de Désactivation

```powershell
# Désactiver les services non critiques
kubectl scale deployment peak-detector-service -n smarthome --replicas=0
kubectl scale deployment optimizer-service -n smarthome --replicas=0
kubectl scale deployment device-simulator-service -n smarthome --replicas=0

# Garder seulement les services essentiels
# - PostgreSQL
# - RabbitMQ
# - Usage Collector
# - Billing
# - Frontend
```

### Réactiver Progressivement

Une fois que les services essentiels fonctionnent :

```powershell
# Réactiver un par un
kubectl scale deployment device-simulator-service -n smarthome --replicas=1
# Attendre qu'il soit prêt
kubectl scale deployment optimizer-service -n smarthome --replicas=1
# Attendre qu'il soit prêt
kubectl scale deployment peak-detector-service -n smarthome --replicas=1
```

## ✅ Solution Alternative 4 : Utiliser un Cluster Cloud

### Options Cloud Gratuites

1. **Google Cloud Platform (GKE)** : 300$ de crédit gratuit
2. **Amazon EKS** : Essai gratuit
3. **Azure AKS** : 200$ de crédit gratuit
4. **DigitalOcean** : 200$ de crédit gratuit

### Avantages
- ✅ Plus de ressources
- ✅ Pas de problèmes de mémoire
- ✅ Scalabilité automatique
- ✅ Meilleure performance

## ✅ Solution Alternative 5 : Utiliser Kind au lieu de Minikube

Kind (Kubernetes in Docker) peut être plus léger :

```powershell
# Installer Kind
choco install kind

# Créer un cluster
kind create cluster --name smarthome --config kind-config.yaml

# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
```

## ✅ Solution Alternative 6 : Utiliser des Images Plus Légères

### PostgreSQL Plus Léger

Utiliser `postgres:16-alpine` au lieu de `postgres:16` :

```yaml
# Dans k8s/databases/postgres-deployment.yaml
image: postgres:16-alpine  # Au lieu de postgres:16
```

### Services Spring Boot

Optimiser les images Docker pour réduire leur taille.

## ✅ Solution Alternative 7 : Utiliser des Services Gérés

### PostgreSQL Géré
- **Supabase** : Gratuit jusqu'à 500MB
- **ElephantSQL** : Gratuit jusqu'à 20MB
- **AWS RDS** : Essai gratuit

### RabbitMQ Géré
- **CloudAMQP** : Plan gratuit disponible
- **RabbitMQ Cloud** : Essai gratuit

### Configuration

Modifier les variables d'environnement des services pour pointer vers les services gérés au lieu des pods Kubernetes.

## 🎯 Solution Recommandée : Docker Compose pour le Développement

Pour le développement local, **Docker Compose est la meilleure solution** :

### Avantages
1. ✅ **Simplicité** : Pas de problèmes de scheduling, probes, etc.
2. ✅ **Ressources** : Utilise directement les ressources de votre machine
3. ✅ **Rapidité** : Démarrage plus rapide
4. ✅ **Débogage** : Plus facile à déboguer
5. ✅ **Stabilité** : Moins de problèmes de stabilité

### Migration

```powershell
# 1. Arrêter Minikube
minikube stop

# 2. Démarrer avec Docker Compose
docker-compose up -d

# 3. Vérifier
docker-compose ps

# 4. Voir les logs
docker-compose logs -f
```

### Garder Kubernetes pour la Production

- Utilisez Docker Compose pour le développement
- Utilisez Kubernetes pour la production/staging
- Les deux peuvent coexister

## 📋 Plan d'Action Recommandé

### Option A : Docker Compose (Développement)

1. Arrêter Minikube
2. Utiliser Docker Compose
3. Développer normalement
4. Déployer sur Kubernetes pour la production

### Option B : Réparer PostgreSQL (Kubernetes)

1. Supprimer et recréer PostgreSQL
2. Attendre que PostgreSQL soit stable
3. Les autres services devraient se connecter automatiquement

### Option C : Architecture Simplifiée

1. Désactiver les services non essentiels
2. Faire fonctionner les services essentiels
3. Réactiver progressivement

## 🔧 Script de Migration vers Docker Compose

Voir `scripts/migrer-vers-docker-compose.ps1` (à créer si nécessaire)

