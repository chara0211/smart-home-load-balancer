# Solution Finale : Mémoire Saturée - RabbitMQ Ne Peut Pas Démarrer

## 🔴 Problème

Même avec Minikube configuré à 4GB de RAM et RabbitMQ réduit à 256Mi, le pod reste en Pending avec "Insufficient memory".

**Cause :** Le cluster a 98% de mémoire allouée. Même 256Mi ne peut pas être alloué.

## ✅ Solutions Possibles

### Solution 1 : Réduire les Ressources des Autres Services (RECOMMANDÉ)

Réduire temporairement les ressources des services Spring Boot pour libérer de la mémoire :

```powershell
# Réduire billing-service
kubectl set resources deployment billing-service -n smarthome --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m

# Réduire usage-collector-service
kubectl set resources deployment usage-collector-service -n smarthome --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m

# Réduire optimizer-service
kubectl set resources deployment optimizer-service -n smarthome --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m

# Réduire peak-detector-service
kubectl set resources deployment peak-detector-service -n smarthome --requests=memory=256Mi,cpu=250m --limits=memory=512Mi,cpu=500m

# Réduire device-simulator-service
kubectl set resources deployment device-simulator-service -n smarthome --requests=memory=128Mi,cpu=100m --limits=memory=256Mi,cpu=250m
```

Puis supprimer les pods pour qu'ils redémarrent avec les nouvelles ressources :
```powershell
kubectl delete pod -n smarthome -l app=billing-service --grace-period=0 --force
kubectl delete pod -n smarthome -l app=usage-collector-service --grace-period=0 --force
kubectl delete pod -n smarthome -l app=optimizer-service --grace-period=0 --force
kubectl delete pod -n smarthome -l app=peak-detector-service --grace-period=0 --force
kubectl delete pod -n smarthome -l app=device-simulator-service --grace-period=0 --force
```

### Solution 2 : Augmenter Encore Plus Minikube (Si Possible)

Si votre machine a assez de RAM (8GB+ disponible) :

```powershell
minikube stop
minikube start --memory=6144 --cpus=4
```

### Solution 3 : Désactiver Temporairement Certains Services

Désactiver temporairement les services non critiques pour libérer de la mémoire :

```powershell
# Mettre à 0 replicas les services non essentiels
kubectl scale deployment peak-detector-service -n smarthome --replicas=0
kubectl scale deployment optimizer-service -n smarthome --replicas=0
kubectl scale deployment device-simulator-service -n smarthome --replicas=0

# Attendre que RabbitMQ démarre
kubectl get pods -n smarthome -l app=rabbitmq -w

# Une fois RabbitMQ prêt, réactiver les services
kubectl scale deployment peak-detector-service -n smarthome --replicas=1
kubectl scale deployment optimizer-service -n smarthome --replicas=1
kubectl scale deployment device-simulator-service -n smarthome --replicas=1
```

### Solution 4 : Utiliser un Cluster Plus Grand

Si vous avez accès à un cluster Kubernetes plus grand (cloud ou autre), déployez-y l'application.

## 📋 Plan d'Action Recommandé

1. **Exécuter la Solution 1** (réduire les ressources)
2. **Attendre 2-3 minutes** pour que les pods redémarrent
3. **Vérifier que RabbitMQ démarre** : `kubectl get pods -n smarthome -l app=rabbitmq`
4. **Si toujours en Pending**, exécuter la Solution 3 (désactiver temporairement certains services)

## 🔍 Vérification

Après avoir appliqué les solutions :

```powershell
# Vérifier l'utilisation mémoire
kubectl describe node | Select-String -Pattern "Allocated resources:" -Context 0,3

# Vérifier RabbitMQ
kubectl get pods -n smarthome -l app=rabbitmq

# Vérifier tous les pods
kubectl get pods -n smarthome
```

## ⚠️ Note Importante

Avec un cluster Minikube limité, il est normal d'avoir des contraintes de ressources. Les solutions ci-dessus sont des compromis pour faire fonctionner tous les services avec des ressources limitées.

Une fois que RabbitMQ est prêt, les services Spring Boot devraient automatiquement se connecter et devenir prêts.


