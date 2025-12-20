# Solution : Erreur ErrImagePull pour PostgreSQL

## 🔴 Problème

Vous obtenez l'erreur `ErrImagePull` avec le message :
```
TLS handshake timeout
Failed to pull image "postgres:16"
```

Cela signifie que Minikube (ou Docker) ne peut pas se connecter à Docker Hub pour télécharger l'image.

## ✅ Solutions

### Solution 1 : Vérifier la Connexion Internet

```powershell
# Tester la connexion à Docker Hub
Test-NetConnection registry-1.docker.io -Port 443

# Tester avec curl
curl https://registry-1.docker.io/v2/
```

Si ces commandes échouent, vous avez un problème de connexion réseau ou de proxy.

---

### Solution 2 : Configurer le Proxy dans Minikube

Si vous utilisez un proxy, configurez-le dans Minikube :

```powershell
# Arrêter Minikube
minikube stop

# Redémarrer Minikube avec les variables de proxy
$env:HTTP_PROXY="http://votre-proxy:port"
$env:HTTPS_PROXY="http://votre-proxy:port"
$env:NO_PROXY="localhost,127.0.0.1"

minikube start --docker-env HTTP_PROXY=$env:HTTP_PROXY --docker-env HTTPS_PROXY=$env:HTTPS_PROXY --docker-env NO_PROXY=$env:NO_PROXY
```

---

### Solution 3 : Utiliser l'Image Docker Desktop (Recommandé)

Si Docker Desktop fonctionne, chargez l'image dans Minikube :

```powershell
# 1. Télécharger l'image avec Docker Desktop (si possible)
# Si Docker Desktop ne peut pas non plus, passez à la Solution 4

# 2. Charger l'image dans Minikube
minikube image load postgres:16

# 3. Vérifier que l'image est chargée
minikube image ls | Select-String postgres

# 4. Modifier le deployment pour utiliser l'image locale
# Modifiez k8s/databases/postgres-deployment.yaml :
# image: postgres:16
# En :
# image: postgres:16
# imagePullPolicy: Never  # Utilise l'image locale
```

---

### Solution 4 : Utiliser une Image Alternative ou Déjà Présente

Vérifiez si vous avez déjà une image PostgreSQL :

```powershell
# Voir les images Docker disponibles
docker images | Select-String postgres

# Voir les images dans Minikube
minikube image ls
```

Si vous avez une image PostgreSQL (même une version différente), vous pouvez :

1. **Modifier le deployment pour utiliser cette image** :
   ```powershell
   # Éditer le fichier
   notepad k8s/databases/postgres-deployment.yaml
   ```
   
   Changez :
   ```yaml
   image: postgres:16
   ```
   
   En (par exemple, si vous avez postgres:15) :
   ```yaml
   image: postgres:15
   imagePullPolicy: IfNotPresent
   ```

2. **Re-appliquer le deployment** :
   ```powershell
   kubectl apply -f k8s/databases/postgres-deployment.yaml
   ```

---

### Solution 5 : Utiliser un Registry Alternatif

Si Docker Hub est bloqué, utilisez un registry alternatif :

```powershell
# Modifier le deployment pour utiliser un registry alternatif
# Par exemple, utiliser quay.io ou gcr.io
```

Modifiez `k8s/databases/postgres-deployment.yaml` :
```yaml
image: quay.io/postgres/postgres:16
# ou
image: gcr.io/google-samples/postgres:16
```

---

### Solution 6 : Télécharger l'Image Manuellement (Si Possible)

Si vous avez accès à un autre ordinateur avec Internet :

1. Sur l'autre ordinateur :
   ```bash
   docker pull postgres:16
   docker save postgres:16 -o postgres-16.tar
   ```

2. Transférez le fichier `postgres-16.tar` sur votre machine

3. Chargez l'image :
   ```powershell
   docker load -i postgres-16.tar
   minikube image load postgres:16
   ```

---

### Solution 7 : Utiliser Minikube avec Docker Driver (Si Problème de Réseau)

Si vous utilisez un autre driver (hyperv, virtualbox), essayez avec Docker :

```powershell
# Arrêter Minikube
minikube stop
minikube delete

# Redémarrer avec Docker driver
minikube start --driver=docker
```

---

## 🎯 Solution Recommandée (Ordre de Priorité)

1. **Essayez d'abord la Solution 3** : Charger l'image dans Minikube si Docker Desktop peut la télécharger
2. **Si ça ne fonctionne pas, Solution 4** : Utiliser une image déjà présente
3. **Si vous avez un proxy, Solution 2** : Configurer le proxy
4. **En dernier recours, Solution 5** : Utiliser un registry alternatif

---

## 🔍 Vérification Après Correction

Une fois le problème résolu :

```powershell
# Supprimer le pod en erreur
kubectl delete pod -l app=postgres -n smarthome

# Le deployment créera automatiquement un nouveau pod
kubectl get pods -n smarthome -l app=postgres

# Attendre que le pod soit Running
kubectl wait --for=condition=ready pod -l app=postgres -n smarthome --timeout=300s
```

---

## 📝 Note Importante

Si vous continuez à avoir des problèmes de connexion réseau, cela peut être dû à :
- Un firewall qui bloque Docker Hub
- Un proxy mal configuré
- Des restrictions réseau (entreprise, école, etc.)
- Un problème DNS

Dans ce cas, contactez votre administrateur réseau ou utilisez un réseau différent.

