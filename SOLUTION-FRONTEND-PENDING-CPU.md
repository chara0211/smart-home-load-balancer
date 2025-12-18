# Solution : Frontend en Pending - Problème de CPU

## 🔴 Problème

Les pods du frontend restent en état `Pending` avec l'erreur :
```
Insufficient cpu. no new claims to deallocate
```

**Cause :** Le cluster Minikube n'a plus assez de CPU disponible (100% alloué).

## ✅ Solutions

### Solution 1 : Augmenter les ressources de Minikube (Recommandé)

Arrêtez Minikube et redémarrez-le avec plus de CPU :

```powershell
# Arrêter Minikube
minikube stop

# Redémarrer avec plus de CPU (4 cores au lieu de 2)
minikube start --cpus=4 --memory=4096

# Vérifier les ressources
kubectl top nodes
```

### Solution 2 : Réduire les ressources d'autres services

Réduisez temporairement le nombre de réplicas d'autres services :

```powershell
# Réduire les réplicas du peak-detector (de 2 à 1)
kubectl scale deployment peak-detector-service --replicas=1 -n smarthome

# Puis redémarrer le frontend
kubectl rollout restart deployment/frontend -n smarthome
```

### Solution 3 : Réduire encore plus les ressources du frontend

Modifiez `k8s/services/frontend/deployment.yaml` :

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "25m"  # Réduit à 25m
  limits:
    memory: "128Mi"
    cpu: "100m"
```

Puis :
```powershell
kubectl apply -f k8s/services/frontend/deployment.yaml
```

### Solution 4 : Arrêter temporairement un service non critique

```powershell
# Arrêter temporairement l'optimizer (si pas utilisé)
kubectl scale deployment optimizer-service --replicas=0 -n smarthome

# Vérifier que le frontend démarre
kubectl get pods -n smarthome -l app=frontend
```

## 🎯 Solution Recommandée

**Pour le développement :** Utilisez la **Solution 1** (augmenter les ressources de Minikube).

**Pour un déploiement rapide :** Utilisez la **Solution 2** (réduire les réplicas d'autres services).

## 📊 Vérification

Après avoir appliqué une solution :

```powershell
# Vérifier que les pods démarrent
kubectl get pods -n smarthome -l app=frontend

# Vérifier les ressources disponibles
kubectl top nodes
kubectl describe nodes
```

## ⚠️ Note

Le frontend a été configuré avec :
- **1 réplica** (au lieu de 2)
- **50m CPU** demandé (au lieu de 100m)
- **128Mi mémoire** demandée (au lieu de 256Mi)

Ces valeurs sont minimales pour le développement. En production, vous devriez avoir plus de ressources disponibles.

