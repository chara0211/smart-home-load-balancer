# Solution pour Usage Collector Service - Health Check 503

## 🔴 Problème

Le pod `usage-collector-service-5b45665fd8-nxzt9` est en statut "Running" mais pas "Ready" (0/1) à cause d'erreurs de health checks :
- `Startup probe failed: HTTP probe failed with statuscode: 503`
- `Container failed liveness probe, will be restarted`

Le service fonctionne (il reçoit des événements RabbitMQ), mais les health checks échouent car Spring Boot inclut Keycloak dans les vérifications de santé.

## ✅ Solution Appliquée

### 1. Configuration des Health Groups

Ajout de la configuration dans `application-kubernetes.properties` pour :
- Exclure Keycloak des health checks
- Configurer les health groups (liveness/readiness) pour ne vérifier que les dépendances essentielles

**readinessProbe** vérifie :
- `readinessState` : État de préparation du service
- `db` : Connexion PostgreSQL
- `rabbit` : Connexion RabbitMQ
- **Exclut Keycloak** (non bloquant pour la disponibilité du service)

**livenessProbe** vérifie :
- `livenessState` : Le service est vivant

### 2. Mise à jour des Probes

Les probes ont été optimisées avec :
- Timeout augmenté à 10 secondes pour readiness et liveness
- Endpoint `/actuator/health/startup` pour startupProbe
- `successThreshold: 1` ajouté explicitement

## 🚀 Actions Requises

### Étape 1 : Reconstruire l'image Docker

```powershell
cd billing-service
docker build -t salmaidoufkir/usage-collector-service:latest .
docker push salmaidoufkir/usage-collector-service:latest
```

**OU** si vous avez déjà fait des modifications, reconstruire :

```powershell
cd usage-collector-service
docker build -t salmaidoufkir/usage-collector-service:latest .
docker push salmaidoufkir/usage-collector-service:latest
```

### Étape 2 : Appliquer le nouveau deployment

```powershell
kubectl apply -f k8s/services/usage-collector/deployment.yaml
```

### Étape 3 : Forcer le redémarrage

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
```

### Étape 4 : Surveiller

```powershell
kubectl get pods -n smarthome -l app=usage-collector-service -w
```

## 📊 Résultat Attendu

Après reconstruction et redéploiement, le pod devrait devenir `1/1 Ready` :

```
NAME                                       READY   STATUS    RESTARTS   AGE
usage-collector-service-xxx                1/1     Running   0          Xm
```

## 🔍 Vérification

Pour vérifier que les health checks fonctionnent :

```powershell
# Port-forward vers le pod
kubectl port-forward -n smarthome <pod-name> 8083:8083

# Tester les endpoints (dans un autre terminal)
curl http://localhost:8083/actuator/health/readiness
curl http://localhost:8083/actuator/health/liveness
```

Les réponses devraient être `{"status":"UP"}` au lieu de `503`.

## ⚠️ Note Importante

Les modifications dans `application-kubernetes.properties` nécessitent une **reconstruction de l'image Docker** pour prendre effet. La simple mise à jour du deployment ne suffira pas.






