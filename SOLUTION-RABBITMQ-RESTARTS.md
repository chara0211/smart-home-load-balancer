# Solution : RabbitMQ Redémarrages Constants

## 🔴 Problème Identifié

RabbitMQ redémarre constamment (11 restarts en 26h) car :

1. **Timeouts trop courts** : Les probes timeout avant que RabbitMQ ne réponde
2. **RabbitMQ prend 3-4 minutes à démarrer** : "Time to start RabbitMQ: 221202 ms" (221 secondes)
3. **Liveness probe échoue** : `timeoutSeconds: 30` est trop court, RabbitMQ peut prendre plus de temps à répondre

## ✅ Solution Appliquée

### Corrections des Probes

**Avant** :
```yaml
startupProbe:
  initialDelaySeconds: 60
  timeoutSeconds: 60        # ❌ Trop long, mais peut encore timeout
  failureThreshold: 40

livenessProbe:
  initialDelaySeconds: 180
  timeoutSeconds: 30        # ❌ Trop court !
  failureThreshold: 5       # ❌ Trop peu de tentatives

readinessProbe:
  initialDelaySeconds: 120
  timeoutSeconds: 60        # ❌ Peut timeout sous charge
  failureThreshold: 10
```

**Après** :
```yaml
startupProbe:
  initialDelaySeconds: 120  # ✅ Attendre 2 minutes avant de commencer
  timeoutSeconds: 10         # ✅ Timeout court mais suffisant pour ping
  failureThreshold: 40      # ✅ 40 × 15s = 10 minutes max

livenessProbe:
  initialDelaySeconds: 300  # ✅ Attendre 5 minutes après le démarrage
  timeoutSeconds: 10        # ✅ Timeout court mais suffisant
  failureThreshold: 10       # ✅ 10 × 30s = 5 minutes de tolérance

readinessProbe:
  initialDelaySeconds: 180  # ✅ Attendre 3 minutes après le démarrage
  timeoutSeconds: 10        # ✅ Timeout court mais suffisant
  failureThreshold: 10      # ✅ 10 × 15s = 2,5 minutes de tolérance
```

## 📝 Explication

### Pourquoi RabbitMQ prend 3-4 minutes à démarrer ?

D'après les logs :
- Initialisation des plugins (30-60s)
- Démarrage de la base de données (30-60s)
- Démarrage des listeners (10-20s)
- Initialisation complète (30-60s)

**Total : 2-4 minutes** selon les ressources disponibles.

### Pourquoi les timeouts étaient trop longs ?

Le problème n'était pas la durée du timeout, mais :
1. **Liveness probe** : `timeoutSeconds: 30` mais RabbitMQ peut prendre plus de temps à répondre sous charge
2. **Readiness probe** : `timeoutSeconds: 60` peut timeout si RabbitMQ est occupé
3. **Startup probe** : `timeoutSeconds: 60` mais RabbitMQ prend 221 secondes à démarrer

**Solution** : Réduire les timeouts à 10 secondes (suffisant pour `rabbitmq-diagnostics ping`) mais augmenter les `initialDelaySeconds` et `failureThreshold` pour donner plus de temps.

## ✅ Résultat Attendu

- ✅ RabbitMQ démarre en 3-4 minutes sans redémarrages
- ✅ Les probes attendent assez longtemps
- ✅ Pas de timeouts prématurés
- ✅ Le service reste stable

## 🧪 Test

Surveillez le pod :

```powershell
kubectl get pods -n smarthome -l app=rabbitmq -w
```

Le pod devrait :
- Démarrer en 3-4 minutes
- Devenir `Ready` sans redémarrages
- Rester stable (restarts = 0 ou 1)

