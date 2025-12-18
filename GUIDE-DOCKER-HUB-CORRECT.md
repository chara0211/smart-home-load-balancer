# Guide : Utilisation Correcte de Docker Hub

## 🔍 Problème Identifié

Vous avez créé vos images sur **Docker Hub**, mais les deployments Kubernetes pointent vers `salmaidoufkir.com`, qui n'est **pas un domaine Docker Hub**.

## ✅ Solution : Utiliser Docker Hub Correctement

### Comment Docker Hub Fonctionne

Docker Hub utilise ces domaines :
- **`docker.io`** (domaine principal)
- **`hub.docker.com`** (interface web)

Les images sur Docker Hub ont ce format :
```
docker.io/USERNAME/IMAGE_NAME:TAG
```

Ou simplement :
```
USERNAME/IMAGE_NAME:TAG
```
(Docker utilise `docker.io` par défaut)

### Si Votre Compte Docker Hub est "salmaidoufkir"

Vos images sur Docker Hub sont accessibles comme :
```
docker.io/salmaidoufkir/usage-collector-service:latest
```

Ou simplement :
```
salmaidoufkir/usage-collector-service:latest
```

---

## 🔧 Correction pour Votre Collègue

### Option 1 : Mettre à Jour les Deployments pour Utiliser Docker Hub

Votre collègue doit mettre à jour les images dans les deployments pour utiliser Docker Hub :

```powershell
# Usage Collector Service
kubectl set image deployment/usage-collector-service usage-collector-service=salmaidoufkir/usage-collector-service:latest -n smarthome

# Device Simulator Service
kubectl set image deployment/device-simulator-service device-simulator-service=salmaidoufkir/device-simulator-service:latest -n smarthome

# Optimizer Service
kubectl set image deployment/optimizer-service optimizer-service=salmaidoufkir/optimizer-service:latest -n smarthome

# Peak Detector Service
kubectl set image deployment/peak-detector-service peak-detector-service=salmaidoufkir/peak-detector-service:latest -n smarthome
```

### Option 2 : Se Connecter à Docker Hub

Votre collègue doit se connecter à Docker Hub (pas à `salmaidoufkir.com`) :

```powershell
# Se connecter à Docker Hub
docker login

# Ou explicitement
docker login docker.io
```

Elle entrera :
- **Username** : `salmaidoufkir` (ou votre nom d'utilisateur Docker Hub)
- **Password** : Votre mot de passe Docker Hub

### Option 3 : Créer le Secret Kubernetes pour Docker Hub

Si les images sont **publiques** sur Docker Hub, pas besoin de secret.

Si les images sont **privées**, créer le secret :

```powershell
kubectl create secret docker-registry dockerhub-secret `
  --docker-server=docker.io `
  --docker-username=salmaidoufkir `
  --docker-password=VOTRE_MOT_DE_PASSE_DOCKER_HUB `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

**⚠️ Important** : Les deployments doivent référencer `dockerhub-secret` au lieu de `registry-secret`, OU vous pouvez renommer le secret :

```powershell
# Supprimer l'ancien secret (si existe)
kubectl delete secret registry-secret -n smarthome

# Créer le nouveau secret avec le nom attendu
kubectl create secret docker-registry registry-secret `
  --docker-server=docker.io `
  --docker-username=salmaidoufkir `
  --docker-password=VOTRE_MOT_DE_PASSE_DOCKER_HUB `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

---

## 📋 Vérification

### Vérifier que les Images Existent sur Docker Hub

1. **Aller sur** : https://hub.docker.com/u/salmaidoufkir
2. **Vérifier** que les images sont listées :
   - `usage-collector-service`
   - `device-simulator-service`
   - `optimizer-service`
   - `peak-detector-service`

### Tester l'Accès depuis la Machine de Votre Collègue

```powershell
# Se connecter à Docker Hub
docker login

# Tester en pullant une image
docker pull salmaidoufkir/usage-collector-service:latest
```

Si cela fonctionne, les images sont accessibles.

---

## 🔄 Mettre à Jour les Fichiers de Deployment (Optionnel)

Si vous voulez que les fichiers YAML pointent directement vers Docker Hub au lieu de `salmaidoufkir.com`, vous pouvez les modifier, mais **ce n'est pas nécessaire** - votre collègue peut utiliser `kubectl set image` comme montré ci-dessus.

---

## 🚀 Solution Complète pour Votre Collègue

Voici les étapes complètes que votre collègue doit suivre :

### Étape 1 : Se Connecter à Docker Hub

```powershell
docker login
# Entrer : salmaidoufkir / VOTRE_MOT_DE_PASSE
```

### Étape 2 : Tester l'Accès

```powershell
docker pull salmaidoufkir/usage-collector-service:latest
```

Si cela fonctionne, continuez. Sinon, vérifiez que :
- Les images sont bien publiées sur Docker Hub
- Les images sont publiques OU votre collègue a accès au compte

### Étape 3 : Mettre à Jour les Images dans Kubernetes

```powershell
kubectl set image deployment/usage-collector-service usage-collector-service=salmaidoufkir/usage-collector-service:latest -n smarthome
kubectl set image deployment/device-simulator-service device-simulator-service=salmaidoufkir/device-simulator-service:latest -n smarthome
kubectl set image deployment/optimizer-service optimizer-service=salmaidoufkir/optimizer-service:latest -n smarthome
kubectl set image deployment/peak-detector-service peak-detector-service=salmaidoufkir/peak-detector-service:latest -n smarthome
```

### Étape 4 : Créer le Secret (si Images Privées)

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=docker.io `
  --docker-username=salmaidoufkir `
  --docker-password=VOTRE_MOT_DE_PASSE_DOCKER_HUB `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

### Étape 5 : Redémarrer les Services

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

### Étape 6 : Vérifier

```powershell
kubectl get pods -n smarthome
```

Les pods devraient maintenant démarrer correctement.

---

## 🔐 Images Publiques vs Privées

### ✅ Si les Images sont Publiques (Votre Cas)

- ✅ **Pas besoin de secret Kubernetes**
- ✅ **Pas besoin de `docker login`**
- ✅ **N'importe qui peut puller les images**
- ✅ **Votre collègue peut utiliser directement les images**

**Solution simplifiée** : Voir **[SOLUTION-IMAGES-PUBLIQUES-DOCKER-HUB.md](SOLUTION-IMAGES-PUBLIQUES-DOCKER-HUB.md)**

### Si les Images sont Privées

- Besoin d'un secret Kubernetes
- Votre collègue doit avoir accès au compte Docker Hub
- OU vous devez l'ajouter comme collaborateur sur votre organisation Docker Hub

---

## 📝 Résumé

**Le problème** : Les deployments pointent vers `salmaidoufkir.com` qui n'existe pas comme registry Docker.

**La solution** : Utiliser `salmaidoufkir/IMAGE_NAME` (Docker Hub) au lieu de `salmaidoufkir.com/IMAGE_NAME`.

**Commandes pour votre collègue** :
```powershell
# 1. Se connecter à Docker Hub
docker login

# 2. Mettre à jour les images
kubectl set image deployment/usage-collector-service usage-collector-service=salmaidoufkir/usage-collector-service:latest -n smarthome
kubectl set image deployment/device-simulator-service device-simulator-service=salmaidoufkir/device-simulator-service:latest -n smarthome
kubectl set image deployment/optimizer-service optimizer-service=salmaidoufkir/optimizer-service:latest -n smarthome
kubectl set image deployment/peak-detector-service peak-detector-service=salmaidoufkir/peak-detector-service:latest -n smarthome

# 3. Créer le secret (si images privées)
kubectl create secret docker-registry registry-secret --docker-server=docker.io --docker-username=salmaidoufkir --docker-password=VOTRE_MDP --docker-email=VOTRE_EMAIL -n smarthome

# 4. Redémarrer
kubectl rollout restart deployment -n smarthome
```

---

## 🆘 Si les Images ne Sont Pas sur Docker Hub

Si vous n'avez pas encore publié les images sur Docker Hub, vous devez :

1. **Construire les images** :
   ```powershell
   docker build -t salmaidoufkir/usage-collector-service:latest ./usage-collector-service
   docker build -t salmaidoufkir/device-simulator-service:latest ./device-simulator-service
   docker build -t salmaidoufkir/optimizer-service:latest ./optimizer-service
   docker build -t salmaidoufkir/peak-detector-service:latest ./peak-detector-service
   ```

2. **Se connecter à Docker Hub** :
   ```powershell
   docker login
   ```

3. **Pusher les images** :
   ```powershell
   docker push salmaidoufkir/usage-collector-service:latest
   docker push salmaidoufkir/device-simulator-service:latest
   docker push salmaidoufkir/optimizer-service:latest
   docker push salmaidoufkir/peak-detector-service:latest
   ```

4. **Rendre les images publiques** (optionnel) :
   - Aller sur https://hub.docker.com/u/salmaidoufkir
   - Pour chaque image, aller dans Settings → Make Public

---

**En résumé** : Utilisez `salmaidoufkir/IMAGE_NAME` (Docker Hub) au lieu de `salmaidoufkir.com/IMAGE_NAME` (qui n'existe pas).

