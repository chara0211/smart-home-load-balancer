# Guide : Résolution du Problème DNS du Registry

## 🔴 Problème

Vous obtenez l'erreur :
```
dial tcp: lookup salmaidoufkir.com: no such host
```

Cela signifie que le domaine `salmaidoufkir.com` n'est **pas accessible publiquement** ou n'est **pas configuré dans le DNS**.

## ✅ Solutions

### Solution 1 : Vérifier si le Registry est Local/Privé

Le registry `salmaidoufkir.com` est probablement un **registry privé local** qui n'est pas accessible publiquement. Vous avez plusieurs options :

#### Option A : Utiliser l'IP au Lieu du Domaine

Si vous connaissez l'IP du registry :

```powershell
# Se connecter avec l'IP
docker login <IP_DU_REGISTRY>

# Exemple
docker login 192.168.1.100
```

#### Option B : Configurer le Fichier Hosts

Si le registry est sur un serveur local avec un nom de domaine privé :

1. **Obtenir l'IP du serveur** (demandez à l'administrateur)

2. **Modifier le fichier hosts** :
   - Ouvrir `C:\Windows\System32\drivers\etc\hosts` en tant qu'administrateur
   - Ajouter : `<IP_DU_SERVEUR> salmaidoufkir.com`
   - Exemple : `192.168.1.100 salmaidoufkir.com`

3. **Tester la connexion** :
   ```powershell
   ping salmaidoufkir.com
   docker login salmaidoufkir.com
   ```

---

### Solution 2 : Utiliser un Registry Public (Alternative)

Si vous n'avez pas accès au registry privé, vous pouvez utiliser **Docker Hub** ou construire les images localement.

#### Option A : Utiliser Docker Hub

1. **Créer un compte sur Docker Hub** : https://hub.docker.com

2. **Se connecter à Docker Hub** :
   ```powershell
   docker login
   ```

3. **Construire et pusher les images** :
   ```powershell
   # Construire avec votre nom d'utilisateur Docker Hub
   docker build -t VOTRE_USERNAME/usage-collector-service:latest ./usage-collector-service
   docker push VOTRE_USERNAME/usage-collector-service:latest
   
   # Répéter pour les autres services
   ```

4. **Mettre à jour les deployments Kubernetes** :
   ```powershell
   kubectl set image deployment/usage-collector-service usage-collector-service=VOTRE_USERNAME/usage-collector-service:latest -n smarthome
   ```

#### Option B : Construire les Images Localement (Recommandé pour Minikube)

C'est la solution la plus simple si vous travaillez localement :

1. **Activer l'environnement Docker de Minikube** :
   ```powershell
   minikube docker-env | Invoke-Expression
   ```

2. **Construire les images localement** :
   ```powershell
   cd usage-collector-service
   docker build -t salmaidoufkir.com/usage-collector-service:latest .
   cd ..
   
   cd device-simulator-service
   docker build -t salmaidoufkir.com/device-simulator-service:latest .
   cd ..
   
   cd optimizer-service
   docker build -t salmaidoufkir.com/optimizer-service:latest .
   cd ..
   
   cd peak-detector-service
   docker build -t salmaidoufkir.com/peak-detector-service:latest .
   cd ..
   ```

3. **Configurer les deployments pour utiliser les images locales** :
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

4. **Redémarrer les services** :
   ```powershell
   kubectl rollout restart deployment/usage-collector-service -n smarthome
   kubectl rollout restart deployment/device-simulator-service -n smarthome
   kubectl rollout restart deployment/optimizer-service -n smarthome
   kubectl rollout restart deployment/peak-detector-service -n smarthome
   ```

---

### Solution 3 : Vérifier avec l'Administrateur

Si le registry `salmaidoufkir.com` est géré par quelqu'un d'autre :

1. **Demander l'IP ou l'URL complète** du registry
2. **Demander les identifiants** d'accès
3. **Demander si le registry nécessite un VPN** ou une connexion spéciale
4. **Demander la configuration DNS** nécessaire

---

## 🔍 Diagnostic

### Vérifier si le Domaine est Accessible

```powershell
# Tester la résolution DNS
nslookup salmaidoufkir.com

# Tester la connexion
ping salmaidoufkir.com

# Tester avec curl
curl https://salmaidoufkir.com
```

### Vérifier la Configuration Docker

```powershell
# Voir la configuration Docker
docker info

# Voir les registries configurés
docker system info | findstr Registry
```

---

## 💡 Solution Recommandée pour Votre Cas

Étant donné que vous travaillez avec **Minikube localement**, la **Solution 2 - Option B** (construire les images localement) est la plus simple et la plus rapide :

### Étapes Rapides

```powershell
# 1. Activer Docker de Minikube
minikube docker-env | Invoke-Expression

# 2. Construire toutes les images
docker build -t salmaidoufkir.com/usage-collector-service:latest ./usage-collector-service
docker build -t salmaidoufkir.com/device-simulator-service:latest ./device-simulator-service
docker build -t salmaidoufkir.com/optimizer-service:latest ./optimizer-service
docker build -t salmaidoufkir.com/peak-detector-service:latest ./peak-detector-service

# 3. Configurer les deployments pour utiliser les images locales
kubectl patch deployment usage-collector-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"usage-collector-service","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment device-simulator-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"device-simulator-service","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment optimizer-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"optimizer-service","imagePullPolicy":"Never"}]}}}}'
kubectl patch deployment peak-detector-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"peak-detector-service","imagePullPolicy":"Never"}]}}}}'

# 4. Redémarrer les services
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome

# 5. Vérifier
kubectl get pods -n smarthome
```

---

## 📋 Checklist

- [ ] J'ai essayé de me connecter au registry : `docker login salmaidoufkir.com`
- [ ] J'ai vérifié si le domaine est accessible : `ping salmaidoufkir.com`
- [ ] J'ai demandé l'IP/URL à l'administrateur (si applicable)
- [ ] J'ai configuré le fichier hosts (si registry local)
- [ ] J'ai construit les images localement (solution alternative)
- [ ] Les pods démarrent maintenant sans erreur `ImagePullBackOff`

---

## 🆘 Si Rien ne Fonctionne

1. **Vérifier avec votre collègue** : Comment a-t-elle configuré l'accès au registry ?
2. **Vérifier la documentation du projet** : Y a-t-il des instructions spécifiques ?
3. **Utiliser la solution locale** : Construire les images dans Minikube (Solution 2 - Option B)

---

**Note** : Pour un environnement de développement local avec Minikube, construire les images localement est généralement la meilleure solution car elle ne nécessite pas de connexion externe.

