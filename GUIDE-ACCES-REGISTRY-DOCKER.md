# Guide : Accès au Registry Docker salmaidoufkir.com

Ce guide explique comment accéder à votre registry Docker privé `salmaidoufkir.com` et l'utiliser avec Kubernetes.

## 🔐 Accès au Registry

### Option 1 : Via Docker CLI (Ligne de Commande)

#### Étape 1 : Se Connecter au Registry

```powershell
docker login salmaidoufkir.com
```

Vous serez invité à entrer :
- **Username** : Votre nom d'utilisateur
- **Password** : Votre mot de passe
- **Email** : Votre email (optionnel)

#### Étape 2 : Vérifier la Connexion

```powershell
# Voir les images disponibles (si le registry le permet)
docker search salmaidoufkir.com/usage-collector-service

# Ou tester en pullant une image
docker pull salmaidoufkir.com/usage-collector-service:latest
```

### Option 2 : Via Interface Web (si disponible)

Si votre registry a une interface web, accédez-y via :
```
https://salmaidoufkir.com
```

Connectez-vous avec vos identifiants pour voir les images disponibles.

---

## 🚀 Utilisation avec Kubernetes

### Étape 1 : Créer le Secret Kubernetes

Une fois que vous êtes connecté au registry, créez le secret Kubernetes :

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=salmaidoufkir.com `
  --docker-username=VOTRE_USERNAME `
  --docker-password=VOTRE_PASSWORD `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

**⚠️ Remplacez** :
- `VOTRE_USERNAME` : Votre nom d'utilisateur pour le registry
- `VOTRE_PASSWORD` : Votre mot de passe pour le registry
- `VOTRE_EMAIL` : Votre email

### Étape 2 : Vérifier le Secret

```powershell
kubectl get secret registry-secret -n smarthome
kubectl describe secret registry-secret -n smarthome
```

### Étape 3 : Les Deployments Utiliseront Automatiquement le Secret

Les fichiers de deployment sont déjà configurés pour utiliser `imagePullSecrets: registry-secret`, donc une fois le secret créé, les pods pourront télécharger les images.

---

## 📦 Publier des Images sur le Registry

Si vous devez publier/pusher des images sur le registry :

### Étape 1 : Construire l'Image avec le Tag du Registry

```powershell
# Usage Collector Service
cd usage-collector-service
docker build -t salmaidoufkir.com/usage-collector-service:latest .
cd ..

# Device Simulator Service
cd device-simulator-service
docker build -t salmaidoufkir.com/device-simulator-service:latest .
cd ..

# Optimizer Service
cd optimizer-service
docker build -t salmaidoufkir.com/optimizer-service:latest .
cd ..

# Peak Detector Service
cd peak-detector-service
docker build -t salmaidoufkir.com/peak-detector-service:latest .
cd ..
```

### Étape 2 : Se Connecter au Registry

```powershell
docker login salmaidoufkir.com
```

### Étape 3 : Pusher les Images

```powershell
# Pusher chaque image
docker push salmaidoufkir.com/usage-collector-service:latest
docker push salmaidoufkir.com/device-simulator-service:latest
docker push salmaidoufkir.com/optimizer-service:latest
docker push salmaidoufkir.com/peak-detector-service:latest
```

### Étape 4 : Vérifier que les Images sont Disponibles

```powershell
# Tester en pullant une image
docker pull salmaidoufkir.com/usage-collector-service:latest
```

---

## 🔍 Vérifier les Images Disponibles

### Via Docker CLI

```powershell
# Lister les images locales taguées avec votre registry
docker images | findstr salmaidoufkir

# Tester le pull d'une image
docker pull salmaidoufkir.com/usage-collector-service:latest
```

### Via kubectl (après avoir créé le secret)

```powershell
# Créer un pod de test pour vérifier l'accès
kubectl run test-registry --image=salmaidoufkir.com/usage-collector-service:latest --restart=Never -n smarthome

# Vérifier le statut
kubectl get pod test-registry -n smarthome

# Voir les logs si erreur
kubectl describe pod test-registry -n smarthome

# Supprimer le pod de test
kubectl delete pod test-registry -n smarthome
```

---

## 🐛 Dépannage

### Erreur : "unauthorized: authentication required"

**Cause** : Vous n'êtes pas connecté au registry ou les identifiants sont incorrects.

**Solution** :
```powershell
# Se reconnecter
docker login salmaidoufkir.com

# Vérifier que vous êtes connecté
docker info | findstr salmaidoufkir
```

### Erreur : "pull access denied"

**Cause** : Vous n'avez pas les permissions pour puller cette image.

**Solutions** :
1. Vérifier que vous êtes connecté : `docker login salmaidoufkir.com`
2. Vérifier que vous avez les droits d'accès à cette image
3. Vérifier que l'image existe dans le registry

### Erreur : "connection refused" ou "no such host"

**Cause** : Le registry n'est pas accessible ou l'URL est incorrecte.

**Solutions** :
1. Vérifier que le registry est accessible : `ping salmaidoufkir.com`
2. Vérifier l'URL du registry
3. Vérifier votre connexion Internet
4. Vérifier si le registry nécessite HTTPS : `https://salmaidoufkir.com`

### Le Secret Kubernetes ne Fonctionne Pas

**Vérifications** :
```powershell
# Vérifier que le secret existe
kubectl get secret registry-secret -n smarthome

# Vérifier le contenu (les valeurs seront encodées en base64)
kubectl get secret registry-secret -n smarthome -o yaml

# Vérifier que les deployments référencent le secret
kubectl get deployment usage-collector-service -n smarthome -o yaml | findstr imagePullSecrets
```

**Si le secret n'est pas référencé**, les deployments doivent avoir :
```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: registry-secret
```

---

## 🔐 Sécurité

### Bonnes Pratiques

1. **Ne jamais commiter les mots de passe** dans Git
2. **Utiliser des secrets Kubernetes** pour stocker les identifiants
3. **Utiliser des tokens d'accès** plutôt que des mots de passe si possible
4. **Limiter les permissions** : donner uniquement les droits nécessaires

### Rotation des Mots de Passe

Si vous changez votre mot de passe du registry :

```powershell
# Supprimer l'ancien secret
kubectl delete secret registry-secret -n smarthome

# Créer un nouveau secret avec le nouveau mot de passe
kubectl create secret docker-registry registry-secret `
  --docker-server=salmaidoufkir.com `
  --docker-username=VOTRE_USERNAME `
  --docker-password=NOUVEAU_MOT_DE_PASSE `
  --docker-email=VOTRE_EMAIL `
  -n smarthome

# Redémarrer les deployments pour utiliser le nouveau secret
kubectl rollout restart deployment -n smarthome
```

---

## 📋 Checklist

Avant d'utiliser le registry avec Kubernetes :

- [ ] Je peux me connecter au registry : `docker login salmaidoufkir.com`
- [ ] Je peux puller une image de test : `docker pull salmaidoufkir.com/usage-collector-service:latest`
- [ ] Le secret Kubernetes est créé : `kubectl get secret registry-secret -n smarthome`
- [ ] Les deployments référencent le secret (vérifié dans les fichiers YAML)
- [ ] Les pods peuvent télécharger les images (pas d'erreur `ImagePullBackOff`)

---

## 🆘 Obtenir de l'Aide

Si vous ne savez pas comment accéder au registry :

1. **Vérifier avec votre administrateur** : Qui gère le registry `salmaidoufkir.com` ?
2. **Vérifier la documentation** : Y a-t-il une documentation pour ce registry ?
3. **Vérifier les emails** : Avez-vous reçu des identifiants par email ?
4. **Vérifier l'interface web** : Le registry a-t-il une interface web accessible ?

---

## 💡 Astuces

### Tester l'Accès Rapidement

```powershell
# Test rapide : essayer de puller une image
docker pull salmaidoufkir.com/usage-collector-service:latest
```

Si cela fonctionne, vous avez accès au registry.

### Voir les Images Disponibles

Si le registry le permet :
```powershell
# Via Docker Hub API (si compatible)
curl https://salmaidoufkir.com/v2/_catalog

# Ou via l'interface web du registry
```

### Utiliser un Token au Lieu d'un Mot de Passe

Certains registries permettent d'utiliser des tokens d'accès :

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=salmaidoufkir.com `
  --docker-username=VOTRE_USERNAME `
  --docker-password=VOTRE_TOKEN `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

---

**Note** : Si vous n'avez pas accès au registry `salmaidoufkir.com`, vous pouvez construire les images localement et les utiliser dans Minikube. Voir `GUIDE-DEPANNAGE-IMAGEPULLBACKOFF.md` - Solution 2.

