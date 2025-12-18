# Solution : Pods Frontend en Pending - Problème de CPU

## 🔴 Problème

Les pods frontend restent en état `Pending` avec l'erreur :
```
Insufficient cpu. no new claims to deallocate
```

**Cause :** Le cluster Minikube n'a plus assez de CPU disponible (100% alloué).

## ✅ Solution Appliquée

### 1. Réduction du nombre de réplicas

```powershell
kubectl scale deployment frontend --replicas=1 -n smarthome
```

### 2. Nettoyage des anciens ReplicaSets

```powershell
kubectl delete replicaset -l app=frontend -n smarthome
```

### 3. Libération de CPU en arrêtant temporairement un service

```powershell
# Arrêter temporairement l'optimizer-service
kubectl scale deployment optimizer-service --replicas=0 -n smarthome
```

## 📊 État Actuel

- ✅ **Frontend** : 1 réplica (Running)
- ⏸️ **Optimizer** : 0 réplicas (arrêté temporairement)

## 🔄 Pour Redémarrer l'Optimizer Plus Tard

Quand vous aurez plus de ressources (après avoir augmenté Minikube) :

```powershell
kubectl scale deployment optimizer-service --replicas=1 -n smarthome
```

## 🚀 Solution Permanente : Augmenter les Ressources de Minikube

Pour éviter ce problème à l'avenir, augmentez les ressources de Minikube :

```powershell
# Arrêter Minikube
minikube stop

# Redémarrer avec plus de CPU et mémoire
minikube start --cpus=4 --memory=4096

# Vérifier les ressources
kubectl top nodes
```

## 📋 Vérification

Vérifiez que le frontend fonctionne :

```powershell
# Vérifier les pods
kubectl get pods -n smarthome -l app=frontend

# Vérifier les logs
kubectl logs -f deployment/frontend -n smarthome

# Accéder au frontend
kubectl port-forward service/frontend-service 3000:3000 -n smarthome
```

Puis ouvrez : **http://localhost:3000**

## ⚠️ Note

Le frontend est maintenant configuré pour utiliser les services backend via leurs NodePorts (`http://172.30.95.94:30083`). Une fois que le pod est Running, il devrait fonctionner correctement.

