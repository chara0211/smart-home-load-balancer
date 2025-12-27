# Solution Finale : RabbitMQ CrashLoopBackOff

## 🔴 Problème

RabbitMQ était en `CrashLoopBackOff` avec l'erreur :
```
error: RABBITMQ_VM_MEMORY_HIGH_WATERMARK is set but deprecated
error: deprecated environment variables detected
```

## 🔍 Causes Identifiées

1. **Variable d'environnement dépréciée** : `RABBITMQ_VM_MEMORY_HIGH_WATERMARK` est dépréciée dans les nouvelles versions de RabbitMQ et fait crasher le conteneur
2. **Mauvaise commande pour startup probe** : `rabbitmqctl status` nécessite que RabbitMQ soit déjà démarré, donc ne fonctionne pas pour les startup probes
3. **Timeouts trop courts** : Même avec `rabbitmq-diagnostics ping`, les timeouts de 10-15s étaient insuffisants

## ✅ Solution Appliquée

### 1. Suppression des Variables Dépréciées

**Supprimé :**
- `RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.6` (dépréciée)
- `RABBITMQ_DISK_FREE_LIMIT=2GB` (dépréciée)

**Raison :** Ces variables sont dépréciées dans RabbitMQ 3.x. La gestion de la mémoire se fait maintenant via les limites de ressources Kubernetes.

### 2. Correction des Probes

**Revenu à `rabbitmq-diagnostics ping`** mais avec des timeouts beaucoup plus longs :

#### Startup Probe
- **Commande** : `rabbitmq-diagnostics ping`
- **initialDelaySeconds** : 30s
- **periodSeconds** : 10s
- **timeoutSeconds** : **30s** (au lieu de 5-10s)
- **failureThreshold** : 30

#### Readiness Probe
- **Commande** : `rabbitmq-diagnostics ping`
- **initialDelaySeconds** : 60s
- **periodSeconds** : 10s
- **timeoutSeconds** : **30s** (au lieu de 10-15s)
- **failureThreshold** : 5

#### Liveness Probe
- **Commande** : `rabbitmq-diagnostics ping`
- **initialDelaySeconds** : 180s
- **periodSeconds** : 30s
- **timeoutSeconds** : **30s** (au lieu de 15-20s)
- **failureThreshold** : 5

### 3. Gestion de la Mémoire

La mémoire est maintenant gérée uniquement via les limites Kubernetes :
- **Requests** : `512Mi`
- **Limits** : `1.5Gi`

RabbitMQ utilisera automatiquement jusqu'à 1.5Gi selon les besoins, et Kubernetes limitera l'utilisation.

## 📋 Configuration Finale

```yaml
env:
  - name: RABBITMQ_DEFAULT_USER
    valueFrom:
      secretKeyRef:
        name: rabbitmq-secret
        key: username
  - name: RABBITMQ_DEFAULT_PASS
    valueFrom:
      secretKeyRef:
        name: rabbitmq-secret
        key: password
# Plus de variables dépréciées

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1.5Gi"
    cpu: "1000m"
```

## ⏱️ Temps de Démarrage Attendu

Avec les nouvelles configurations :
- **Startup probe** : Commence après 30s, vérifie toutes les 10s avec timeout de 30s
- **Readiness probe** : Commence après 60s, vérifie toutes les 10s avec timeout de 30s
- **Temps total pour être prêt** : ~2-3 minutes après le démarrage du conteneur

## 🔍 Vérification

Après 3-5 minutes, RabbitMQ devrait être prêt :

```powershell
kubectl get pods -n smarthome -l app=rabbitmq
```

**Résultat attendu :** `1/1 Ready` et `Running`

## 📝 Notes Importantes

1. **Variables dépréciées** : Ne plus utiliser `RABBITMQ_VM_MEMORY_HIGH_WATERMARK` dans RabbitMQ 3.x
2. **Gestion mémoire** : Laisser Kubernetes gérer via les limites de ressources
3. **Timeouts longs** : 30s timeout est nécessaire car `rabbitmq-diagnostics ping` peut être lent, surtout au démarrage
4. **Startup probe** : Doit utiliser `rabbitmq-diagnostics ping`, pas `rabbitmqctl status` (qui nécessite RabbitMQ déjà démarré)

## 🐛 Si le Problème Persiste

Si RabbitMQ n'est toujours pas prêt :

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
kubectl exec -n smarthome <rabbitmq-pod> -- rabbitmq-diagnostics ping
```

4. **Vérifier les ressources :**
```powershell
kubectl describe node
```

Si le problème persiste, il peut être nécessaire de réduire encore plus les ressources ou d'augmenter les ressources du cluster.


