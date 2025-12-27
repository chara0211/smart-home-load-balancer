# Solution : RabbitMQ Ne Devient Jamais Prêt

## 🔴 Problème

RabbitMQ reste en `0/1 Ready` avec des redémarrages constants. Les readiness probes échouent avec des timeouts.

## 🔍 Causes Identifiées

1. **Startup probe trop courte** : 5s timeout est insuffisant pour RabbitMQ qui démarre lentement
2. **`rabbitmq-diagnostics ping` est lent** : Cette commande peut prendre beaucoup de temps, surtout si RabbitMQ est sous charge mémoire
3. **Alerte mémoire** : `system_memory_high_watermark` ralentit RabbitMQ
4. **Probes exec timeout** : Les commandes exec peuvent timeout avant que RabbitMQ ne réponde

## ✅ Solution Appliquée

### Changement de Stratégie de Probes

**Avant :** Utilisation de `rabbitmq-diagnostics ping` avec timeouts courts
**Après :** Utilisation de `rabbitmqctl status` avec timeouts plus longs

### Nouvelles Configurations

#### Startup Probe
- **Commande** : `rabbitmqctl status` (plus rapide et fiable)
- **initialDelaySeconds** : 60s (au lieu de 10s)
- **periodSeconds** : 15s (au lieu de 10s)
- **timeoutSeconds** : 20s (au lieu de 5s)
- **failureThreshold** : 30

#### Readiness Probe
- **Commande** : `rabbitmqctl status`
- **initialDelaySeconds** : 90s (au lieu de 30s)
- **periodSeconds** : 15s (au lieu de 15s)
- **timeoutSeconds** : 20s (au lieu de 15s)
- **failureThreshold** : 5

#### Liveness Probe
- **Commande** : `rabbitmqctl status`
- **initialDelaySeconds** : 180s
- **periodSeconds** : 30s
- **timeoutSeconds** : 20s (au lieu de 15s)
- **failureThreshold** : 5

### Pourquoi `rabbitmqctl status` est Meilleur

1. **Plus rapide** : `rabbitmqctl status` est généralement plus rapide que `rabbitmq-diagnostics ping`
2. **Plus fiable** : Retourne un code de sortie clair (0 = OK, non-0 = erreur)
3. **Moins de charge** : Moins de ressources système que `ping`
4. **Meilleur pour les probes** : Conçu pour vérifier l'état du serveur

## 📋 Application de la Solution

La configuration a été appliquée automatiquement. Le pod RabbitMQ va redémarrer avec les nouvelles configurations.

**Vérifiez l'état :**
```powershell
kubectl get pods -n smarthome -l app=rabbitmq
kubectl logs -n smarthome -l app=rabbitmq --tail=50
```

## ⏱️ Temps de Démarrage Attendu

Avec les nouvelles configurations :
- **Startup probe** : Commence après 60s, vérifie toutes les 15s
- **Readiness probe** : Commence après 90s, vérifie toutes les 15s
- **Temps total pour être prêt** : ~2-3 minutes après le démarrage du conteneur

## 🔍 Vérification

Après 3-5 minutes, RabbitMQ devrait être prêt :

```powershell
kubectl get pods -n smarthome -l app=rabbitmq
```

**Résultat attendu :** `1/1 Ready` et `Running`

## 🐛 Si le Problème Persiste

Si RabbitMQ n'est toujours pas prêt après 5 minutes :

1. **Vérifier les logs :**
```powershell
kubectl logs -n smarthome -l app=rabbitmq --tail=100
```

2. **Vérifier les événements :**
```powershell
kubectl describe pod -n smarthome -l app=rabbitmq
```

3. **Tester manuellement :**
```powershell
kubectl exec -n smarthome <rabbitmq-pod> -- rabbitmqctl status
```

4. **Vérifier les ressources :**
```powershell
kubectl describe node
```

Si RabbitMQ manque de mémoire, vous pouvez réduire les limites dans le déploiement.

## 📝 Notes

- Les timeouts ont été augmentés significativement pour donner plus de temps à RabbitMQ
- `rabbitmqctl status` est plus approprié pour les health checks que `rabbitmq-diagnostics ping`
- La mémoire est limitée à 60% pour éviter les alertes (`RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.6`)


