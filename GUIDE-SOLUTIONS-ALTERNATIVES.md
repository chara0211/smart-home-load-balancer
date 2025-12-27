# Guide des Solutions Alternatives - Pods Non Prêts

## 🔴 Problème Principal Identifié

**PostgreSQL** crash constamment avec l'erreur `FATAL: role "root" does not exist` à cause de probes mal configurées.

## ✅ Solution 1 : Correction PostgreSQL (APPLIQUÉE)

### Problème
Les probes PostgreSQL utilisaient `$(POSTGRES_USER)` qui n'était pas correctement résolu, causant l'utilisation de "root" par défaut.

### Correction Appliquée
- ✅ Probes corrigées pour utiliser `/bin/sh -c` avec `$${POSTGRES_USER}`
- ✅ Timeouts augmentés (15s au lieu de 5s)
- ✅ Startup probe ajoutée
- ✅ Ressources augmentées (512Mi au lieu de 256Mi)

**Attendez 2-3 minutes** pour que PostgreSQL démarre avec la nouvelle configuration.

## ✅ Solution 2 : Utiliser Docker Compose (RECOMMANDÉ pour le développement)

### Pourquoi Docker Compose ?

1. **Plus simple** : Pas de problèmes de scheduling, probes, etc.
2. **Moins de ressources** : Utilise directement votre machine
3. **Plus rapide** : Démarrage plus rapide
4. **Plus stable** : Moins de problèmes de stabilité
5. **Idéal pour le développement** : Parfait pour développer localement

### Migration

```powershell
# Exécuter le script de migration
.\scripts\migrer-vers-docker-compose.ps1
```

Ou manuellement :

```powershell
# 1. Arrêter Minikube
minikube stop

# 2. Démarrer avec Docker Compose
docker-compose up -d

# 3. Vérifier
docker-compose ps
```

### Avantages

- ✅ Tous les services démarrent rapidement
- ✅ Pas de problèmes de mémoire
- ✅ Facile à déboguer
- ✅ Logs accessibles facilement

## ✅ Solution 3 : Réinitialiser PostgreSQL

Si PostgreSQL ne démarre toujours pas après la correction :

```powershell
# Exécuter le script de réparation
.\scripts\reparer-postgresql.ps1
```

**⚠️ ATTENTION :** Cela supprimera toutes les données PostgreSQL !

## ✅ Solution 4 : Désactiver les Services Non Essentiels

Pour libérer de la mémoire et faire fonctionner les services essentiels :

```powershell
# Exécuter le script
.\scripts\desactiver-services-non-essentiels.ps1
```

Cela désactivera :
- peak-detector-service
- optimizer-service
- device-simulator-service

Et gardera actifs :
- postgres
- rabbitmq
- usage-collector-service
- billing-service
- frontend
- keycloak

## ✅ Solution 5 : Utiliser un Cluster Cloud

Si vous avez accès à un cluster cloud (GKE, EKS, AKS), vous aurez :
- ✅ Plus de ressources
- ✅ Pas de problèmes de mémoire
- ✅ Meilleure performance

## 🎯 Recommandation Finale

### Pour le Développement Local

**Utilisez Docker Compose** :
```powershell
.\scripts\migrer-vers-docker-compose.ps1
```

### Pour la Production/Staging

**Utilisez Kubernetes** avec les corrections appliquées :
1. ✅ PostgreSQL corrigé (probes)
2. ✅ RabbitMQ corrigé (timeouts)
3. ✅ Services Spring Boot corrigés (probes)
4. ✅ Ressources optimisées

## 📋 Plan d'Action Immédiat

### Option A : Attendre la Correction PostgreSQL (2-3 minutes)

1. La correction PostgreSQL a été appliquée
2. Attendez 2-3 minutes
3. Vérifiez : `kubectl get pods -n smarthome -l app=postgres`
4. Si PostgreSQL est prêt, les autres services devraient se connecter

### Option B : Migrer vers Docker Compose (5 minutes)

1. Exécutez : `.\scripts\migrer-vers-docker-compose.ps1`
2. Tous les services démarreront rapidement
3. Développez normalement

### Option C : Réinitialiser PostgreSQL (5 minutes)

1. Exécutez : `.\scripts\reparer-postgresql.ps1`
2. PostgreSQL sera recréé proprement
3. Les autres services se connecteront automatiquement

## 🔍 Vérification

Après avoir choisi une solution :

```powershell
# Pour Kubernetes
kubectl get pods -n smarthome

# Pour Docker Compose
docker-compose ps
```

## 📝 Scripts Disponibles

1. **`scripts/migrer-vers-docker-compose.ps1`** - Migration vers Docker Compose
2. **`scripts/reparer-postgresql.ps1`** - Réinitialiser PostgreSQL
3. **`scripts/desactiver-services-non-essentiels.ps1`** - Désactiver services non essentiels
4. **`scripts/correction-complete-cluster.ps1`** - Correction complète du cluster

## ⚠️ Note Importante

**Pour le développement local**, Docker Compose est **fortement recommandé** car :
- Plus simple à gérer
- Moins de problèmes
- Démarrage plus rapide
- Facile à déboguer

**Kubernetes** est mieux pour :
- Production
- Staging
- Tests d'intégration
- Déploiements complexes

