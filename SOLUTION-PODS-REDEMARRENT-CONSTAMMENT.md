# Solution : Pods qui redémarrent constamment

## 🔴 Problème Identifié

Les pods redémarrent constamment (20+ restarts) et ne deviennent jamais `Ready` car :

1. **Health checks retournent 401** : Spring Security bloque `/actuator/health` malgré `permitAll()`
2. **Services prennent 3-4 minutes à démarrer** : Les probes attendent seulement 30-60 secondes
3. **Pods tués trop tôt** : Les liveness probes tuent les pods avant qu'ils soient prêts

## ✅ Solutions à Appliquer

### 1. Corriger Spring Security pour les Health Checks

Les endpoints `/actuator/health` doivent être accessibles **AVANT** que Spring Security soit complètement initialisé.

**Solution** : Utiliser `management.endpoints.web.base-path` et s'assurer que les endpoints sont exempts de sécurité.

### 2. Augmenter les Timeouts des Probes

Les services Spring Boot prennent **3-4 minutes** à démarrer complètement. Les probes doivent attendre assez longtemps :

- **Startup Probe** : `initialDelaySeconds: 60`, `failureThreshold: 60` (10 minutes max)
- **Readiness Probe** : `initialDelaySeconds: 180` (3 minutes après le démarrage)
- **Liveness Probe** : `initialDelaySeconds: 300` (5 minutes après le démarrage)

### 3. Augmenter les Failure Thresholds

Pour éviter de tuer les pods trop rapidement :

- **Startup** : `failureThreshold: 60` (60 tentatives × 10s = 10 minutes)
- **Liveness** : `failureThreshold: 10` (10 tentatives × 30s = 5 minutes)
- **Readiness** : `failureThreshold: 10` (10 tentatives × 10s = 100 secondes)

### 4. Vérifier les Endpoints de Health

S'assurer que les endpoints suivants sont bien configurés :
- `/actuator/health` (readiness)
- `/actuator/health/liveness` (liveness)
- `/actuator/health/startup` (startup, si disponible)

## 🔧 Corrections à Appliquer

### Étape 1 : Vérifier SecurityConfig

Tous les services doivent avoir dans leur `SecurityConfig.java` :

```java
.requestMatchers("/actuator/health/**", "/actuator/info", "/actuator/health").permitAll()
```

### Étape 2 : Mettre à Jour les Deployments

Ajuster les probes pour tous les services Spring Boot :

```yaml
startupProbe:
  httpGet:
    path: /actuator/health
    port: 8086
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 10
  failureThreshold: 60  # 60 × 10s = 10 minutes max

readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8086
  initialDelaySeconds: 180  # Attendre 3 minutes après le démarrage
  periodSeconds: 10
  timeoutSeconds: 10
  failureThreshold: 10

livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8086
  initialDelaySeconds: 300  # Attendre 5 minutes après le démarrage
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 10
```

### Étape 3 : Réduire les Ressources (si nécessaire)

Si les services manquent de mémoire, réduire les requests :

```yaml
resources:
  requests:
    memory: "512Mi"  # Au lieu de 768Mi
    cpu: "500m"
  limits:
    memory: "1Gi"    # Au lieu de 2Gi
    cpu: "1000m"
```

## 🧪 Test

Après avoir appliqué les corrections :

```powershell
# Surveiller les pods
kubectl get pods -n smarthome -w

# Vérifier les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 20

# Vérifier les logs d'un service
kubectl logs -n smarthome billing-service-xxx --tail=50
```

## ✅ Résultat Attendu

- ✅ Les pods démarrent en 3-4 minutes et deviennent `Ready`
- ✅ Pas de redémarrages constants
- ✅ Les health checks retournent 200 (au lieu de 401)
- ✅ Les services sont stables et fonctionnels

