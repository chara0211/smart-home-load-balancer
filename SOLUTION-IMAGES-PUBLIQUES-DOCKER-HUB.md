# Solution : Images Publiques sur Docker Hub

## ✅ Bonne Nouvelle

Vos images sont **publiques** sur Docker Hub, donc votre collègue peut y accéder **sans authentification** !

## 🚀 Solution Simplifiée pour Votre Collègue

### Étape 1 : Mettre à Jour les Images dans Kubernetes

Les deployments pointent vers `salmaidoufkir.com` qui n'existe pas. Il faut les mettre à jour pour utiliser Docker Hub :

```powershell
kubectl set image deployment/usage-collector-service usage-collector-service=salmaidoufkir/usage-collector-service:latest -n smarthome

kubectl set image deployment/device-simulator-service device-simulator-service=salmaidoufkir/device-simulator-service:latest -n smarthome

kubectl set image deployment/optimizer-service optimizer-service=salmaidoufkir/optimizer-service:latest -n smarthome

kubectl set image deployment/peak-detector-service peak-detector-service=salmaidoufkir/peak-detector-service:latest -n smarthome
```

### Étape 2 : Supprimer le Secret Registry (Optionnel)

Puisque les images sont publiques, le secret `registry-secret` n'est **pas nécessaire**. Si elle l'a créé, elle peut le supprimer :

```powershell
# Vérifier si le secret existe
kubectl get secret registry-secret -n smarthome

# Si elle veut le supprimer (optionnel)
kubectl delete secret registry-secret -n smarthome
```

**Note** : Même si le secret existe, ça ne posera pas de problème. Kubernetes utilisera simplement les images publiques.

### Étape 3 : Redémarrer les Services

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

### Étape 4 : Vérifier

Attendre 1-2 minutes, puis :

```powershell
kubectl get pods -n smarthome
```

Tous les pods devraient être en état `Running` et `READY 1/1`.

---

## 🧪 Test Rapide

Votre collègue peut tester si les images sont accessibles :

```powershell
# Tester en pullant une image (sans se connecter)
docker pull salmaidoufkir/usage-collector-service:latest
```

Si cela fonctionne, les images sont bien publiques et accessibles.

---

## 📋 Résumé des Commandes

**Commandes complètes à exécuter :**

```powershell
# 1. Mettre à jour les images
kubectl set image deployment/usage-collector-service usage-collector-service=salmaidoufkir/usage-collector-service:latest -n smarthome
kubectl set image deployment/device-simulator-service device-simulator-service=salmaidoufkir/device-simulator-service:latest -n smarthome
kubectl set image deployment/optimizer-service optimizer-service=salmaidoufkir/optimizer-service:latest -n smarthome
kubectl set image deployment/peak-detector-service peak-detector-service=salmaidoufkir/peak-detector-service:latest -n smarthome

# 2. Redémarrer les services
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome

# 3. Vérifier après 1-2 minutes
kubectl get pods -n smarthome
```

**C'est tout !** Pas besoin de :
- ❌ Se connecter à Docker Hub (`docker login`)
- ❌ Créer un secret Kubernetes
- ❌ Configurer quoi que ce soit d'autre

---

## 🔍 Vérification des Images

Votre collègue peut vérifier que les images existent sur Docker Hub :

1. Aller sur : https://hub.docker.com/u/salmaidoufkir
2. Vérifier que les 4 images sont listées et marquées "Public"

---

## ⚠️ Si les Pods ne Démarrant Toujours Pas

### Vérifier les Logs

```powershell
kubectl logs -n smarthome -l app=usage-collector-service --tail=50
```

### Vérifier les Événements

```powershell
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 20
```

### Vérifier le Statut des Pods

```powershell
kubectl describe pod <nom-du-pod> -n smarthome
```

---

## ✅ Checklist

- [ ] Les images sont mises à jour avec `kubectl set image`
- [ ] Les services sont redémarrés
- [ ] Les pods sont en état `Running` et `READY 1/1`
- [ ] Les tests Postman fonctionnent

---

**C'est beaucoup plus simple maintenant que les images sont publiques ! 🎉**

