# Solution : Erreur "broken pipe" lors du push Docker

## 🔴 Problème

Lors du push d'une image vers Docker Hub, vous rencontrez l'erreur :
```
failed to copy: failed to do request: Put "https://registry-1.docker.io/...": write tcp ... write: broken pipe
```

Cette erreur indique que la connexion réseau a été interrompue pendant le transfert.

## 🔍 Causes possibles

1. **Connexion réseau instable** (WiFi, connexion mobile)
2. **Problème de proxy** (configuration incorrecte ou timeout)
3. **Timeout de connexion** (transfert trop long)
4. **Taille de l'image trop importante** (couche de 45MB en cours de transfert)
5. **Limites de Docker Hub** (rate limiting ou restrictions)

## ✅ Solutions

### Solution 1 : Réessayer le push (le plus simple)

Souvent, c'est juste un problème temporaire de réseau :

```powershell
docker push salmaidoufkir/usage-collector-service:latest
```

**Astuce** : Docker reprend automatiquement là où il s'est arrêté pour les couches déjà transférées.

### Solution 2 : Vérifier et configurer le proxy Docker

Si vous utilisez un proxy (comme indiqué dans l'erreur : `192.168.65.1:3128`), configurez-le correctement :

#### Windows - Docker Desktop

1. Ouvrez **Docker Desktop**
2. Allez dans **Settings** → **Resources** → **Proxies**
3. Configurez le proxy :
   - **Web Server (HTTP)** : `http://192.168.65.1:3128`
   - **Secure Web Server (HTTPS)** : `http://192.168.65.1:3128`
   - Cochez **Bypass proxy settings for these hosts & domains** et ajoutez :
     ```
     localhost,127.0.0.1,*.local
     ```

4. Cliquez sur **Apply & Restart**

#### Configuration via fichier daemon.json

Créez/modifiez `C:\Users\<votre-utilisateur>\.docker\daemon.json` :

```json
{
  "proxies": {
    "http-proxy": "http://192.168.65.1:3128",
    "https-proxy": "http://192.168.65.1:3128",
    "no-proxy": "localhost,127.0.0.1,*.local"
  }
}
```

Puis redémarrez Docker Desktop.

### Solution 3 : Augmenter les timeouts

Créez/modifiez le fichier de configuration Docker :

**Windows** : `C:\Users\<votre-utilisateur>\.docker\config.json`

Ajoutez ou modifiez :

```json
{
  "auths": {
    "https://index.docker.io/v1/": {}
  },
  "HttpHeaders": {
    "User-Agent": "Docker-Client"
  },
  "credsStore": "wincred",
  "experimental": "enabled"
}
```

### Solution 4 : Optimiser la taille de l'image

Réduire la taille de l'image peut aider à éviter les timeouts :

#### Vérifier la taille actuelle

```powershell
docker images salmaidoufkir/usage-collector-service:latest
```

#### Optimiser le Dockerfile

Assurez-vous que votre Dockerfile utilise un `.dockerignore` et optimise les couches :

```dockerfile
# Utiliser des images Alpine (plus petites)
FROM eclipse-temurin:17-jre-alpine

# Nettoyer les caches après l'installation
RUN rm -rf /var/cache/apk/*

# Utiliser des multi-stage builds (déjà fait dans votre Dockerfile)
```

#### Créer un .dockerignore

Créez `usage-collector-service/.dockerignore` :

```
target/
.git/
.gitignore
*.md
.idea/
*.iml
.mvn/
mvnw
mvnw.cmd
```

### Solution 5 : Push par couches avec retry

Utilisez un script PowerShell avec retry automatique :

```powershell
# Script de push avec retry
$maxRetries = 3
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        Write-Host "Tentative $($retryCount + 1) de push..."
        docker push salmaidoufkir/usage-collector-service:latest
        $success = $true
        Write-Host "Push réussi !" -ForegroundColor Green
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "Échec, nouvelle tentative dans 10 secondes..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        } else {
            Write-Host "Échec après $maxRetries tentatives" -ForegroundColor Red
        }
    }
}
```

### Solution 6 : Utiliser Docker Buildx avec compression

Buildx peut améliorer la fiabilité du push :

```powershell
# Activer buildx
docker buildx create --use

# Builder et pusher avec compression
docker buildx build --platform linux/amd64 --push \
  -t salmaidoufkir/usage-collector-service:latest \
  ./usage-collector-service
```

### Solution 7 : Vérifier la connexion réseau

Testez votre connexion à Docker Hub :

```powershell
# Tester la connexion
Test-NetConnection registry-1.docker.io -Port 443

# Vérifier la vitesse de connexion
Invoke-WebRequest -Uri "https://registry-1.docker.io/v2/" -UseBasicParsing
```

### Solution 8 : Désactiver temporairement le proxy

Si le proxy cause des problèmes, désactivez-le temporairement :

1. Docker Desktop → Settings → Resources → Proxies
2. Décochez **Manual proxy configuration**
3. Cliquez sur **Apply & Restart**
4. Réessayez le push

### Solution 9 : Utiliser un tag différent et retry

Parfois, changer le tag peut aider :

```powershell
# Taguer avec un nouveau tag
docker tag salmaidoufkir/usage-collector-service:latest salmaidoufkir/usage-collector-service:v1.0.0

# Pusher le nouveau tag
docker push salmaidoufkir/usage-collector-service:v1.0.0

# Si ça fonctionne, pusher aussi latest
docker push salmaidoufkir/usage-collector-service:latest
```

### Solution 10 : Vérifier les limites Docker Hub

Docker Hub a des limites pour les comptes gratuits :
- **Pull** : 200 par 6 heures (anonyme) / 200 par 6 heures (authentifié)
- **Push** : Pas de limite, mais peut être ralenti

Vérifiez votre compte Docker Hub pour voir s'il y a des restrictions.

## 🎯 Solution recommandée (ordre de priorité)

1. **Réessayer simplement** (Solution 1) - 80% des cas
2. **Vérifier le proxy** (Solution 2) - si vous utilisez un proxy
3. **Optimiser l'image** (Solution 4) - pour éviter les futurs problèmes
4. **Utiliser buildx** (Solution 6) - pour plus de fiabilité

## 📝 Commandes utiles

```powershell
# Vérifier l'état de Docker
docker info

# Voir les images locales
docker images | Select-String "usage-collector"

# Vérifier la taille de l'image
docker images salmaidoufkir/usage-collector-service:latest --format "{{.Size}}"

# Nettoyer les images non utilisées
docker image prune -a

# Vérifier la configuration Docker
docker system info
```

## 🔗 Ressources

- [Documentation Docker - Configuration du proxy](https://docs.docker.com/config/daemon/systemd/#httphttps-proxy)
- [Docker Hub - Rate Limiting](https://www.docker.com/blog/scaling-docker-to-serve-millions-more-developers-network-egress/)
- [Optimisation des images Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

