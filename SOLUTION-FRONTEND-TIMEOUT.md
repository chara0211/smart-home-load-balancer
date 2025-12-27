# Solution : Frontend ERR_CONNECTION_TIMED_OUT

## 🔴 Problème

Erreur `ERR_CONNECTION_TIMED_OUT` lors de l'accès à `http://192.168.49.2:30000/`

## ✅ Causes Identifiées

1. **Probes de démarrage trop courtes** : Next.js prend du temps à démarrer
2. **Pod pas encore prêt** : Le pod démarre mais les probes échouent

## ✅ Corrections Appliquées

### 1. Probes de Démarrage Améliorées

Modifié `k8s/services/frontend/deployment.yaml` :
- ✅ `initialDelaySeconds` : 10s → 30s
- ✅ `periodSeconds` : 5s → 10s
- ✅ `timeoutSeconds` : ajouté (5s)

### 2. Vérification de l'État

Le pod frontend devrait maintenant :
- ✅ Démarrer correctement
- ✅ Passer les probes de démarrage
- ✅ Devenir `1/1 Ready`

## 🧪 Vérification

### 1. Vérifier l'État du Pod

```powershell
kubectl get pods -n smarthome -l app=frontend
```

Le pod doit être `1/1 Ready` et `Running`.

### 2. Vérifier les Endpoints

```powershell
kubectl get endpoints -n smarthome frontend-service-nodeport
```

Doit montrer un endpoint actif (ex: `10.244.0.xxx:3000`).

### 3. Tester l'Accès

```powershell
# Obtenir l'IP de Minikube
$minikubeIp = minikube ip
Write-Host "Frontend: http://$minikubeIp:30000"

# Ou utiliser minikube service
minikube service frontend-service-nodeport -n smarthome
```

### 4. Vérifier les Logs

```powershell
kubectl logs -n smarthome -l app=frontend --tail=50
```

Vous devriez voir :
```
✓ Ready in XXXXms
```

## 🐛 Si le Problème Persiste

### Option 1 : Utiliser Port-Forward (Temporaire)

```powershell
kubectl port-forward -n smarthome deployment/frontend 3000:3000
```

Puis accéder à : `http://localhost:3000`

### Option 2 : Vérifier le Service NodePort

```powershell
# Vérifier que le service existe
kubectl get svc -n smarthome frontend-service-nodeport

# Vérifier les détails
kubectl describe svc -n smarthome frontend-service-nodeport
```

### Option 3 : Vérifier Minikube

```powershell
# Vérifier que Minikube est en cours d'exécution
minikube status

# Vérifier les services exposés
minikube service list -n smarthome
```

## 📝 Notes

- Le frontend Next.js prend environ 1-2 secondes à démarrer
- Les probes doivent attendre suffisamment longtemps
- Le service NodePort doit pointer vers un pod prêt

## 🔄 Redéploiement

Si vous avez modifié le code, rebuild et redéployez :

```powershell
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest
kubectl rollout restart deployment/frontend -n smarthome
```

