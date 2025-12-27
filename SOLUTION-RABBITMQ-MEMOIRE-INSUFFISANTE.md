# Solution : RabbitMQ - Mémoire Insuffisante

## 🔴 Problème

RabbitMQ reste en `Pending` avec l'erreur :
```
0/1 nodes are available: 1 Insufficient memory
```

## 🔍 Cause

Le cluster Kubernetes n'a pas assez de mémoire disponible pour allouer les **1Gi** demandés par RabbitMQ.

## ✅ Solution Appliquée

### Réduction des Ressources Demandées

**Avant :**
- Requests: `memory: 1Gi, cpu: 500m`
- Limits: `memory: 2Gi, cpu: 1000m`

**Après :**
- Requests: `memory: 512Mi, cpu: 250m` (réduit de moitié)
- Limits: `memory: 1.5Gi, cpu: 1000m` (légèrement réduit)

### Pourquoi Cela Fonctionne

1. **Requests réduits** : Kubernetes peut maintenant planifier le pod avec moins de mémoire garantie
2. **Limits maintenus** : RabbitMQ peut toujours utiliser jusqu'à 1.5Gi si disponible
3. **CPU réduit** : Moins de CPU garanti, mais toujours jusqu'à 1000m en limite

### Configuration Mémoire RabbitMQ

La variable d'environnement `RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.6` limite RabbitMQ à utiliser 60% de la mémoire disponible, ce qui est compatible avec 512Mi-1.5Gi.

## 📋 Vérification

Après application, vérifiez que RabbitMQ démarre :

```powershell
kubectl get pods -n smarthome -l app=rabbitmq
```

**Résultat attendu :** Le pod devrait passer de `Pending` à `ContainerCreating` puis `Running`.

## ⚠️ Si le Problème Persiste

Si RabbitMQ reste en Pending :

1. **Vérifier les ressources du nœud :**
```powershell
kubectl describe node
```

2. **Libérer de la mémoire en réduisant d'autres services :**
```powershell
# Réduire le nombre de replicas des autres services
kubectl scale deployment/billing-service -n smarthome --replicas=1
kubectl scale deployment/usage-collector-service -n smarthome --replicas=1
kubectl scale deployment/optimizer-service -n smarthome --replicas=1
kubectl scale deployment/peak-detector-service -n smarthome --replicas=1
```

3. **Ou réduire encore plus les ressources de RabbitMQ** (si vraiment nécessaire) :
```yaml
resources:
  requests:
    memory: "256Mi"  # Minimum pour RabbitMQ
    cpu: "100m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

## 📝 Notes

- **512Mi est le minimum recommandé** pour RabbitMQ en production légère
- Avec `RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.6`, RabbitMQ utilisera ~307Mi (60% de 512Mi)
- Si vous avez besoin de plus de performance, augmentez les ressources après avoir libéré de la mémoire dans le cluster


