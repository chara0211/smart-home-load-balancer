# Solution : Configurer Minikube pour Accéder à Docker Hub

## 🔴 Problème

Minikube ne peut pas télécharger les images depuis Docker Hub à cause d'une erreur `TLS handshake timeout`. Vous voulez garder `imagePullPolicy: Always` pour tous vos services.

## ✅ Solutions

### Solution 1 : Configurer le Proxy dans Minikube (Si vous utilisez un proxy)

Si vous êtes derrière un proxy d'entreprise ou un proxy réseau :

```powershell
# 1. Arrêter Minikube
minikube stop

# 2. Configurer les variables d'environnement de proxy
$env:HTTP_PROXY="http://votre-proxy:port"
$env:HTTPS_PROXY="http://votre-proxy:port"
$env:NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"

# 3. Redémarrer Minikube avec les variables de proxy
minikube start --docker-env HTTP_PROXY=$env:HTTP_PROXY --docker-env HTTPS_PROXY=$env:HTTPS_PROXY --docker-env NO_PROXY=$env:NO_PROXY
```

**Exemple avec un proxy typique :**
```powershell
$env:HTTP_PROXY="http://192.168.65.1:3128"
$env:HTTPS_PROXY="http://192.168.65.1:3128"
$env:NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,192.168.65.0/24"

minikube start --docker-env HTTP_PROXY=$env:HTTP_PROXY --docker-env HTTPS_PROXY=$env:HTTPS_PROXY --docker-env NO_PROXY=$env:NO_PROXY
```

### Solution 2 : Configurer Docker dans Minikube pour Utiliser le Proxy Système

Si Docker Desktop fonctionne avec le proxy, configurez Minikube pour utiliser la même configuration :

```powershell
# 1. Arrêter Minikube
minikube stop

# 2. Créer/modifier le fichier de configuration Docker daemon dans Minikube
minikube ssh "sudo mkdir -p /etc/docker"
minikube ssh "echo '{
  \"proxies\": {
    \"http-proxy\": \"http://votre-proxy:port\",
    \"https-proxy\": \"http://votre-proxy:port\",
    \"no-proxy\": \"localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16\"
  }
}' | sudo tee /etc/docker/daemon.json"

# 3. Redémarrer Docker dans Minikube
minikube ssh "sudo systemctl restart docker"

# 4. Redémarrer Minikube
minikube start
```

### Solution 3 : Utiliser Minikube avec Docker Driver (Recommandé)

Si vous utilisez un autre driver (hyperv, virtualbox), essayez avec Docker qui partage la configuration réseau :

```powershell
# 1. Arrêter et supprimer Minikube actuel
minikube stop
minikube delete

# 2. Redémarrer avec Docker driver
minikube start --driver=docker

# 3. Vérifier que Docker Hub est accessible
minikube ssh "docker pull hello-world"
```

### Solution 4 : Configurer les DNS dans Minikube

Si le problème vient de la résolution DNS :

```powershell
# 1. Entrer dans Minikube
minikube ssh

# 2. Dans le shell Minikube, tester la connexion
ping registry-1.docker.io
curl -I https://registry-1.docker.io/v2/

# 3. Si ça ne fonctionne pas, configurer les DNS
sudo echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
sudo echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# 4. Sortir de Minikube
exit

# 5. Redémarrer Minikube
minikube restart
```

### Solution 5 : Utiliser un Registry Mirror (Alternative)

Si Docker Hub est bloqué, configurez un registry mirror :

```powershell
# 1. Arrêter Minikube
minikube stop

# 2. Redémarrer avec un registry mirror
minikube start --registry-mirror=https://mirror.gcr.io
```

### Solution 6 : Vérifier la Configuration Réseau de Minikube

```powershell
# Vérifier l'IP de Minikube
minikube ip

# Tester la connexion depuis Minikube
minikube ssh "curl -I https://registry-1.docker.io/v2/"

# Voir la configuration réseau
minikube ssh "ip addr show"
```

## 🔍 Diagnostic

### Vérifier si le problème vient du réseau

```powershell
# Tester depuis votre machine
Test-NetConnection registry-1.docker.io -Port 443

# Tester depuis Minikube
minikube ssh "curl -I https://registry-1.docker.io/v2/"
```

### Vérifier les logs de Minikube

```powershell
# Voir les logs de Minikube
minikube logs

# Voir les logs Docker dans Minikube
minikube ssh "journalctl -u docker -n 50"
```

## 🎯 Solution Recommandée (Ordre de Priorité)

1. **Solution 3** : Utiliser Docker driver (le plus simple si vous avez Docker Desktop)
2. **Solution 1** : Configurer le proxy si vous êtes derrière un proxy
3. **Solution 4** : Configurer les DNS si c'est un problème de résolution
4. **Solution 2** : Configurer Docker daemon dans Minikube

## 📝 Après Configuration

Une fois la configuration appliquée, testez :

```powershell
# Tester le pull d'une image depuis Minikube
minikube ssh "docker pull postgres:16"

# Si ça fonctionne, vos deployments devraient maintenant fonctionner avec imagePullPolicy: Always
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl get pods -n smarthome -l app=postgres
```

## ⚠️ Note Importante

Si vous continuez à avoir des problèmes après avoir essayé ces solutions, cela peut être dû à :
- Un firewall d'entreprise qui bloque Docker Hub
- Des restrictions réseau strictes
- Un proxy mal configuré

Dans ce cas, contactez votre administrateur réseau ou utilisez un réseau différent (par exemple, un hotspot mobile).

---

**Une fois la configuration appliquée, tous vos services pourront utiliser `imagePullPolicy: Always` et télécharger les images depuis Docker Hub automatiquement.**

