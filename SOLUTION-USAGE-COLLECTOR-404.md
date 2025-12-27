# Solution : Usage Collector Service - Erreur 404 sur Startup Probe

## 🔴 Problème Identifié

Le pod `usage-collector-service` ne devient jamais `Ready` car :

1. **404 sur `/actuator/health/startup`** : L'endpoint n'existe pas
2. **Deux ReplicaSets actifs** : Un ancien ReplicaSet crée des pods en double

## ✅ Solution Appliquée

### 1. Correction du Startup Probe

**Avant** :
```yaml
startupProbe:
  httpGet:
    path: /actuator/health/startup  # ❌ Cet endpoint n'existe pas
    port: 8083
```

**Après** :
```yaml
startupProbe:
  httpGet:
    path: /actuator/health  # ✅ Utiliser l'endpoint standard
    port: 8083
  initialDelaySeconds: 60  # Augmenté de 30 à 60 secondes
```

### 2. Suppression de l'Ancien ReplicaSet

```powershell
kubectl scale replicaset usage-collector-service-b95df8b5 -n smarthome --replicas=0
```

## 📝 Explication

L'endpoint `/actuator/health/startup` nécessite une configuration spécifique dans `application.properties` :

```properties
management.endpoint.health.group.startup.include=startupState,db,rabbit
```

Mais cette configuration n'est pas présente dans `application-kubernetes.properties`, donc l'endpoint n'existe pas.

**Solution** : Utiliser `/actuator/health` qui est toujours disponible et fonctionne pour le startup probe.

## ✅ Résultat Attendu

- ✅ Le startup probe utilise `/actuator/health` (200 OK)
- ✅ Le pod devient `Ready` en 3-4 minutes
- ✅ Plus qu'un seul ReplicaSet actif
- ✅ Le service fonctionne correctement

