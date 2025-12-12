# Guide : Consulter les Images Docker après Push

Ce guide explique comment vérifier et consulter vos images Docker après les avoir poussées vers un registry (Docker Hub, GitHub Container Registry, etc.).

---

## 🔍 Méthodes pour Consulter les Images

### 1. Via Docker Hub (Interface Web)

#### Étape 1 : Se Connecter à Docker Hub

1. Aller sur https://hub.docker.com/
2. Se connecter avec votre compte

#### Étape 2 : Voir Vos Images

**Option A : Depuis votre profil**
1. Cliquer sur votre nom d'utilisateur (en haut à droite)
2. Cliquer sur "Repositories"
3. Vous verrez toutes vos images poussées

**Option B : Recherche directe**
1. Utiliser la barre de recherche en haut
2. Taper : `votre-username/usage-collector-service`
3. Cliquer sur le résultat

#### Étape 3 : Détails d'une Image

Quand vous cliquez sur une image, vous verrez :
- **Tags disponibles** : `latest`, `v1.0`, etc.
- **Date de création** : Quand l'image a été poussée
- **Taille** : Taille de l'image
- **Description** : Si vous en avez ajouté une
- **Commandes** : Comment pull l'image
- **Vulnérabilités** : Scan de sécurité (si activé)

**Exemple d'URL** :
```
https://hub.docker.com/r/votre-username/usage-collector-service
```

---

### 2. Via la Ligne de Commande (Docker CLI)

#### Voir les Images Locales

```bash
# Lister toutes les images locales
docker images

# Filtrer par votre username
docker images | grep votre-username

# Voir une image spécifique
docker images votre-username/usage-collector-service
```

**Exemple de sortie** :
```
REPOSITORY                                    TAG       IMAGE ID       CREATED         SIZE
votre-username/usage-collector-service        latest    abc123def456   2 hours ago     450MB
votre-username/peak-detector-service         latest    def456ghi789   2 hours ago     380MB
votre-username/device-simulator-service      latest    ghi789jkl012   2 hours ago     320MB
votre-username/optimizer-service             latest    jkl012mno345   2 hours ago     410MB
```

#### Vérifier qu'une Image Existe sur Docker Hub

```bash
# Tester le pull (sans vraiment télécharger)
docker pull votre-username/usage-collector-service:latest

# Ou vérifier avec docker manifest (si disponible)
docker manifest inspect votre-username/usage-collector-service:latest
```

#### Voir les Tags d'une Image

```bash
# Utiliser Docker Hub API (nécessite curl ou wget)
curl -s "https://hub.docker.com/v2/repositories/votre-username/usage-collector-service/tags/" | grep -o '"name":"[^"]*"'

# Ou utiliser un outil comme skopeo (si installé)
skopeo list-tags docker://votre-username/usage-collector-service
```

---

### 3. Via Docker Hub API

#### Lister Vos Repositories

```bash
# Remplacer 'votre-username' et 'votre-token'
curl -H "Authorization: JWT votre-token" \
  "https://hub.docker.com/v2/repositories/votre-username/?page_size=100"
```

**Pour obtenir un token** :
1. Aller sur https://hub.docker.com/settings/security
2. Créer un "New Access Token"
3. Utiliser ce token dans la commande

#### Voir les Tags d'une Image Spécifique

```bash
curl "https://hub.docker.com/v2/repositories/votre-username/usage-collector-service/tags/"
```

**Exemple de réponse JSON** :
```json
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "creator": 123456,
      "id": 789012,
      "images": [...],
      "last_updated": "2024-01-15T10:30:00.123456Z",
      "last_updater": 123456,
      "name": "latest",
      "repository": 345678,
      "full_size": 471859200,
      "v2": true
    },
    {
      "name": "v1.0",
      ...
    }
  ]
}
```

---

### 4. Via kubectl (Dans Kubernetes)

#### Vérifier qu'une Image Peut Être Pullée

```bash
# Tester si Kubernetes peut accéder à l'image
kubectl run test-pull --image=votre-username/usage-collector-service:latest --dry-run=client -o yaml

# Voir les événements d'un pod qui essaie de pull une image
kubectl describe pod <pod-name> -n smarthome | grep -i image
```

#### Voir les Images Utilisées dans les Deployments

```bash
# Lister toutes les images utilisées dans le namespace
kubectl get deployments -n smarthome -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}'

# Voir l'image d'un deployment spécifique
kubectl get deployment usage-collector-service -n smarthome -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## 📋 Checklist de Vérification

### Après le Push, Vérifiez :

1. **✅ Image visible sur Docker Hub**
   - Aller sur https://hub.docker.com/
   - Chercher `votre-username/usage-collector-service`
   - Vérifier que l'image apparaît

2. **✅ Tags corrects**
   - Vérifier que le tag `latest` existe
   - Vérifier la date de création (récente)

3. **✅ Pull fonctionne**
   ```bash
   docker pull votre-username/usage-collector-service:latest
   ```

4. **✅ Kubernetes peut l'utiliser**
   - Vérifier que le deployment pointe vers la bonne image
   - Vérifier que `imagePullPolicy` est correct

---

## 🔍 Commandes Utiles pour Vérifier

### Voir Toutes Vos Images sur Docker Hub

```bash
# Via curl (nécessite un token)
TOKEN="votre-token-docker-hub"
USERNAME="votre-username"

curl -H "Authorization: JWT $TOKEN" \
  "https://hub.docker.com/v2/repositories/$USERNAME/?page_size=100" | \
  jq '.results[].name'
```

### Voir les Détails d'une Image

```bash
# Informations complètes d'une image
docker inspect votre-username/usage-collector-service:latest

# Voir l'historique
docker history votre-username/usage-collector-service:latest
```

### Vérifier la Taille

```bash
# Taille locale
docker images votre-username/usage-collector-service

# Taille sur Docker Hub (via API)
curl "https://hub.docker.com/v2/repositories/votre-username/usage-collector-service/tags/latest" | jq '.full_size'
```

---

## 🌐 Autres Registries

### GitHub Container Registry (ghcr.io)

```bash
# Voir vos images
# Aller sur : https://github.com/votre-username?tab=packages

# Ou via API
curl -H "Authorization: token votre-token-github" \
  "https://api.github.com/user/packages?package_type=container"
```

### Google Container Registry (gcr.io)

```bash
# Lister vos images
gcloud container images list

# Voir les tags
gcloud container images list-tags gcr.io/votre-projet/usage-collector-service
```

### Amazon ECR

```bash
# Lister les repositories
aws ecr describe-repositories

# Voir les images
aws ecr list-images --repository-name usage-collector-service
```

---

## 🐛 Problèmes Courants

### Image Non Visible sur Docker Hub

**Causes possibles** :
1. **Push non terminé** : Attendre quelques secondes
2. **Mauvais username** : Vérifier le nom d'utilisateur
3. **Image privée** : Vérifier les paramètres de visibilité
4. **Cache du navigateur** : Rafraîchir la page

**Solutions** :
```bash
# Vérifier que le push a réussi
docker push votre-username/usage-collector-service:latest
# Devrait afficher : "latest: digest: sha256:..."

# Vérifier les logs
docker images | grep votre-username
```

### Erreur "Image Not Found" dans Kubernetes

**Causes possibles** :
1. **Mauvais nom d'image** dans le deployment
2. **Image privée sans secret** : Créer un secret pour le registry
3. **Image n'existe pas** : Vérifier sur Docker Hub

**Solutions** :
```bash
# Vérifier le nom dans le deployment
kubectl get deployment usage-collector-service -n smarthome -o yaml | grep image:

# Tester le pull manuellement
docker pull votre-username/usage-collector-service:latest

# Voir les événements du pod
kubectl describe pod <pod-name> -n smarthome | grep -A 10 Events
```

---

## 📊 Résumé : Comment Consulter

### Méthode la Plus Simple (Recommandée)

1. **Aller sur Docker Hub** : https://hub.docker.com/
2. **Se connecter** avec votre compte
3. **Cliquer sur votre profil** → "Repositories"
4. **Voir toutes vos images** avec leurs détails

### Méthode Rapide (Ligne de Commande)

```bash
# Voir les images locales
docker images | grep votre-username

# Tester le pull
docker pull votre-username/usage-collector-service:latest
```

### Méthode Avancée (API)

```bash
# Via Docker Hub API
curl "https://hub.docker.com/v2/repositories/votre-username/?page_size=100"
```

---

## ✅ Exemple Complet

### Après avoir fait le push :

```bash
# 1. Push des images
docker push votre-username/usage-collector-service:latest
docker push votre-username/peak-detector-service:latest
docker push votre-username/device-simulator-service:latest
docker push votre-username/optimizer-service:latest
```

### Vérification :

```bash
# 2. Voir les images locales
docker images | grep votre-username

# 3. Tester le pull (vérifier que ça fonctionne)
docker pull votre-username/usage-collector-service:latest

# 4. Aller sur Docker Hub pour voir visuellement
# https://hub.docker.com/r/votre-username/usage-collector-service
```

### Dans Kubernetes :

```bash
# 5. Vérifier que le deployment utilise la bonne image
kubectl get deployment usage-collector-service -n smarthome -o jsonpath='{.spec.template.spec.containers[0].image}'

# Devrait afficher : votre-username/usage-collector-service:latest
```

---

## 🎯 Conclusion

**Méthode la plus simple** : Aller sur https://hub.docker.com/ et voir vos images dans votre profil.

**Méthode rapide** : `docker images | grep votre-username`

**Méthode complète** : Combiner les deux pour vérifier localement et sur le registry.

Toutes vos images poussées sont maintenant consultables et utilisables ! 🚀

