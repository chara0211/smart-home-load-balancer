# Solution pour les Problèmes Usage Collector Service

## 🔴 Problèmes Identifiés

### 1. CreateContainerConfigError
Le pod `usage-collector-service-5b45665fd8-nxzt9` avait l'erreur :
```
Error: configmap "services-config" not found
```

**Cause** : Le ConfigMap `services-config` n'existait pas dans le namespace `smarthome`, mais le déploiement référençait les clés `keycloak-url` et `keycloak-realm` de ce ConfigMap.

### 2. CrashLoopBackOff
Les pods `usage-collector-service-f7b68f78d-777wk` et `b9bj4` étaient en CrashLoopBackOff.

**Cause** : Ces pods utilisaient probablement l'ancienne configuration sans le ConfigMap, et crashaient à cause de variables d'environnement manquantes ou de problèmes de connexion.

## ✅ Solution Appliquée

### Étape 1 : Création du ConfigMap

Le ConfigMap `services-config` a été créé avec la commande :
```powershell
kubectl apply -f k8s/configmaps/services-config.yaml
```

Ce ConfigMap contient :
- `keycloak-url`: `http://keycloak-service:8080`
- `keycloak-realm`: `smarthome`
- Autres configurations de services

### Étape 2 : Vérification

Après création du ConfigMap, le nouveau pod devrait démarrer correctement :
```powershell
kubectl get pods -n smarthome -l app=usage-collector-service
```

## 📋 Résultat

- ✅ **ConfigMap créé** : `services-config` est maintenant disponible
- ✅ **Nouveau pod** : `usage-collector-service-5b45665fd8-nxzt9` est en statut "Running"
- ⚠️ **Anciens pods** : Les pods en CrashLoopBackOff peuvent être supprimés

## 🔧 Actions Recommandées

### 1. Supprimer les anciens pods en erreur

```powershell
# Supprimer les anciens ReplicaSets qui ont des pods en erreur
kubectl delete pod usage-collector-service-f7b68f78d-777wk -n smarthome
kubectl delete pod usage-collector-service-f7b68f78d-b9bj4 -n smarthome
```

### 2. Vérifier que le nouveau pod fonctionne

```powershell
# Vérifier les logs
kubectl logs usage-collector-service-5b45665fd8-nxzt9 -n smarthome --tail=50

# Vérifier les health checks
kubectl exec -n smarthome usage-collector-service-5b45665fd8-nxzt9 -- curl http://localhost:8083/actuator/health
```

### 3. Nettoyer les ReplicaSets anciens (optionnel)

Si vous avez plusieurs ReplicaSets, vous pouvez supprimer les anciens :
```powershell
kubectl get rs -n smarthome -l app=usage-collector-service
kubectl delete rs <ancien-replicaset-name> -n smarthome
```

## ⚠️ Note sur registry-secret

Il y a un avertissement sur `registry-secret` manquant :
```
Unable to retrieve some image pull secrets (registry-secret)
```

C'est un **avertissement**, pas une erreur bloquante. Si votre image Docker est publique (ce qui semble être le cas avec `salmaidoufkir/usage-collector-service:latest`), le pull fonctionnera quand même.

Si vous avez besoin du `registry-secret` pour une image privée, créez-le avec :
```powershell
kubectl create secret docker-registry registry-secret \
  --docker-server=docker.io \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com \
  -n smarthome
```

## 📊 État Final Attendu

Après ces actions, vous devriez avoir :
```
NAME                                        READY   STATUS    RESTARTS   AGE
usage-collector-service-xxx                 1/1     Running   0          Xm
```

Le service devrait être opérationnel et recevoir des événements RabbitMQ normalement.






