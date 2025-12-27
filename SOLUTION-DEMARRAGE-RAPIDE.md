# Solution Radicale pour Démarrage Rapide des Pods

## 🎯 Objectif

Accélérer drastiquement le démarrage des pods en optimisant les probes et les ressources.

## ✅ Changements Appliqués

### 1. **startupProbe ajoutés partout**

Tous les services ont maintenant un `startupProbe` qui :
- Commence après seulement 10 secondes
- Vérifie toutes les 5 secondes
- Permet jusqu'à **60 échecs** (5 minutes max de démarrage)
- Utilise un timeout de 3 secondes

**Services concernés :**
- ✅ peak-detector-service (ajouté)
- ✅ optimizer-service (ajouté)
- ✅ device-simulator-service (ajouté)
- ✅ usage-collector-service (optimisé)
- ✅ billing-service (optimisé)
- ✅ rabbitmq (ajouté)
- ✅ postgres (ajouté)
- ✅ keycloak (optimisé)

### 2. **Ressources Doublées/Triplées**

**Services Spring Boot :**
- CPU requests : `250m` → `500m` (doublé)
- CPU limits : `500m` → `1000m` (doublé)
- Memory requests : `512Mi` → `768Mi` (augmenté de 50%)
- Memory limits : `1Gi` → `2Gi` (doublé)

**RabbitMQ :**
- CPU requests : `250m` → `500m` (doublé)
- CPU limits : `500m` → `1000m` (doublé)
- Memory requests : `512Mi` → `1Gi` (doublé)
- Memory limits : `1Gi` → `2Gi` (doublé)

**PostgreSQL :**
- CPU requests : `250m` → `500m` (doublé)
- CPU limits : `500m` → `1000m` (doublé)
- Memory requests : `256Mi` → `512Mi` (doublé)
- Memory limits : `512Mi` → `1Gi` (doublé)

**Keycloak :**
- CPU requests : `500m` → `750m` (augmenté de 50%)
- CPU limits : `1000m` → `1500m` (augmenté de 50%)
- Memory requests : `1Gi` → `1.5Gi` (augmenté de 50%)
- Memory limits : `2Gi` → `3Gi` (augmenté de 50%)

### 3. **livenessProbe Décalés**

Les `livenessProbe` ne commencent **PAS** avant que le `startupProbe` ne réussisse :
- `initialDelaySeconds` : `60-120s` → `180s` (3 minutes)
- `periodSeconds` : `10s` → `30s` (moins agressif)
- `failureThreshold` : `3` (gardé)

Cela empêche Kubernetes de tuer les pods avant qu'ils ne soient prêts.

### 4. **readinessProbe Optimisés**

- `timeoutSeconds` : `3-5s` (ajouté/standardisé)
- `failureThreshold` : `3` (standardisé)
- `periodSeconds` : `5s` (gardé rapide pour détecter rapidement quand c'est prêt)

## 📊 Résultats Attendus

1. **Démarrage plus rapide** grâce aux ressources augmentées
2. **Pas de redémarrages prématurés** grâce aux startupProbe
3. **Détection rapide quand prêt** grâce aux readinessProbe optimisés
4. **Stabilité** grâce aux livenessProbe décalés

## 🚀 Application des Changements

### Option 1 : Appliquer tous les déploiements

```powershell
# Appliquer tous les déploiements
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/device-simulator/deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/keycloak/keycloak-deployment.yaml
```

### Option 2 : Redémarrage forcé (plus radical)

```powershell
# Forcer la recréation de tous les pods
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/billing-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/rabbitmq -n smarthome
kubectl rollout restart deployment/postgres -n smarthome
kubectl rollout restart deployment/keycloak -n smarthome
```

### Option 3 : Appliquer + Redémarrer (RECOMMANDÉ)

```powershell
# D'abord appliquer les nouvelles configurations
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/device-simulator/deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/keycloak/keycloak-deployment.yaml

# Attendre quelques secondes
Start-Sleep -Seconds 5

# Ensuite redémarrer pour forcer la recréation avec les nouvelles configs
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/billing-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/rabbitmq -n smarthome
kubectl rollout restart deployment/postgres -n smarthome
kubectl rollout restart deployment/keycloak -n smarthome
```

## 📈 Surveillance

Surveillez l'état des pods après application :

```powershell
# Surveiller en temps réel
kubectl get pods -n smarthome -w

# Vérifier l'état après 2-3 minutes
kubectl get pods -n smarthome

# Voir les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 50
```

## ⚠️ Notes Importantes

1. **Ressources** : Ces changements nécessitent plus de ressources CPU/memory sur votre cluster. Assurez-vous que votre cluster peut supporter ces limites.

2. **PostgreSQL et RabbitMQ** : Ces services critiques sont prioritaires, leurs ressources ont été augmentées en premier.

3. **Keycloak** : Le build initial peut toujours prendre 3-5 minutes la première fois, mais avec plus de ressources, ça devrait être plus rapide.

4. **Ordre de démarrage** : Les `startupProbe` permettent aux services de démarrer même si leurs dépendances ne sont pas immédiatement prêtes, réduisant les redémarrages en cascade.

## 🎯 Résultat Final Attendu

Après 5-10 minutes, tous les pods devraient être `1/1 Ready` et `Running` avec `RESTARTS: 0` :

```
NAME                                        READY   STATUS    RESTARTS   AGE
postgres-xxx                                1/1     Running   0          Xm
keycloak-xxx                                1/1     Running   0          Xm
rabbitmq-xxx                                1/1     Running   0          Xm
usage-collector-service-xxx                 1/1     Running   0          Xm
peak-detector-service-xxx                   1/1     Running   0          Xm
optimizer-service-xxx                       1/1     Running   0          Xm
billing-service-xxx                         1/1     Running   0          Xm
device-simulator-service-xxx                1/1     Running   0          Xm
```







