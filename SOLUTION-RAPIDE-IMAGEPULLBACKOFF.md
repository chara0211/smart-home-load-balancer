# Solution Rapide : Erreurs ImagePullBackOff

## 🚨 Problème Actuel

Vous avez des erreurs `ImagePullBackOff` pour tous les services car Kubernetes ne peut pas télécharger les images depuis `salmaidoufkir.com`.

## ⚡ Solution Rapide (Choisissez une option)

### ⚠️ Important : Si vous obtenez "no such host" pour salmaidoufkir.com

Si `docker login salmaidoufkir.com` donne l'erreur "no such host", le registry n'est pas accessible publiquement. **Utilisez directement l'Option 2** (construire les images localement).

### Option 1 : Si vous avez accès au registry salmaidoufkir.com

Créez le secret avec vos identifiants :

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=salmaidoufkir.com `
  --docker-username=VOTRE_USERNAME `
  --docker-password=VOTRE_PASSWORD `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

Puis redémarrez les services :

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

---

### Option 2 : Si vous n'avez PAS accès au registry (Recommandé)

Construisez les images localement :

#### Étape 1 : Activer Docker de Minikube

```powershell
minikube docker-env | Invoke-Expression
```

#### Étape 2 : Construire les Images

```powershell
# Usage Collector
cd usage-collector-service
docker build -t salmaidoufkir.com/usage-collector-service:latest .
cd ..

# Device Simulator
cd device-simulator-service
docker build -t salmaidoufkir.com/device-simulator-service:latest .
cd ..

# Optimizer
cd optimizer-service
docker build -t salmaidoufkir.com/optimizer-service:latest .
cd ..

# Peak Detector
cd peak-detector-service
docker build -t salmaidoufkir.com/peak-detector-service:latest .
cd ..
```

#### Étape 3 : Configurer les Deployments pour Utiliser les Images Locales

```powershell
# Usage Collector
kubectl patch deployment usage-collector-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"usage-collector-service","imagePullPolicy":"Never"}]}}}}'

# Device Simulator
kubectl patch deployment device-simulator-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"device-simulator-service","imagePullPolicy":"Never"}]}}}}'

# Optimizer
kubectl patch deployment optimizer-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"optimizer-service","imagePullPolicy":"Never"}]}}}}'

# Peak Detector
kubectl patch deployment peak-detector-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"peak-detector-service","imagePullPolicy":"Never"}]}}}}'
```

#### Étape 4 : Redémarrer les Services

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

---

## 🔧 Résoudre le Problème RabbitMQ

RabbitMQ est en `CrashLoopBackOff`. Vérifiez et créez le secret si nécessaire :

```powershell
# Vérifier si le secret existe
kubectl get secret rabbitmq-secret -n smarthome

# Si n'existe pas, le créer
kubectl create secret generic rabbitmq-secret `
  --from-literal=username=guest `
  --from-literal=password=guest123 `
  -n smarthome

# Redémarrer RabbitMQ
kubectl delete pod -n smarthome -l app=rabbitmq
```

---

## ✅ Vérification

Attendez 1-2 minutes, puis vérifiez :

```powershell
kubectl get pods -n smarthome
```

Tous les pods devraient être en état `Running` et `READY 1/1`.

---

## 📚 Guide Complet

Pour plus de détails et d'autres solutions, consultez :
👉 **[GUIDE-DEPANNAGE-IMAGEPULLBACKOFF.md](GUIDE-DEPANNAGE-IMAGEPULLBACKOFF.md)**

