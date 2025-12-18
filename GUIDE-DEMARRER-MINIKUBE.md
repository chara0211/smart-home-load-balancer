# Guide pour Démarrer Minikube

Ce guide vous aide à démarrer Minikube sur Windows avec Hyper-V.

## ⚠️ Problème : Permissions Hyper-V

Si vous obtenez l'erreur :
```
Hyper-V requires Administrator privileges
```

Cela signifie que Minikube a besoin de privilèges administrateur pour utiliser Hyper-V.

## ✅ Solution : Démarrer Minikube en tant qu'Administrateur

### Étape 1 : Ouvrir PowerShell en tant qu'Administrateur

1. **Recherchez "PowerShell"** dans le menu Démarrer Windows
2. **Clic droit** sur "Windows PowerShell" ou "PowerShell"
3. Sélectionnez **"Exécuter en tant qu'administrateur"**
4. Cliquez sur **"Oui"** dans la fenêtre de contrôle de compte d'utilisateur

### Étape 2 : Naviguer vers le projet

```powershell
cd D:\Salma\smart-home-load-balancer
```

### Étape 3 : Démarrer Minikube

```powershell
minikube start
```

**Temps d'attente** : Le démarrage peut prendre 2-5 minutes la première fois.

### Étape 4 : Vérifier que Minikube est démarré

```powershell
# Vérifier le statut
minikube status

# Obtenir l'IP
minikube ip
```

Vous devriez voir quelque chose comme :
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## 🔄 Alternatives si Hyper-V ne fonctionne pas

### Option 1 : Utiliser Docker Desktop comme driver

Si vous avez Docker Desktop installé et en cours d'exécution :

```powershell
# Supprimer le profil existant (si nécessaire)
minikube delete

# Démarrer avec Docker driver
minikube start --driver=docker
```

### Option 2 : Utiliser VirtualBox

Si vous avez VirtualBox installé :

```powershell
# Supprimer le profil existant
minikube delete

# Démarrer avec VirtualBox
minikube start --driver=virtualbox
```

### Option 3 : Utiliser WSL2

Si vous avez WSL2 installé :

```powershell
# Supprimer le profil existant
minikube delete

# Démarrer avec Docker dans WSL2
minikube start --driver=docker
```

## 🛠️ Commandes Utiles

### Vérifier le driver actuel

```powershell
minikube config get driver
```

### Changer de driver

```powershell
minikube config set driver docker
# ou
minikube config set driver virtualbox
```

### Arrêter Minikube

```powershell
minikube stop
```

### Redémarrer Minikube

```powershell
minikube start
```

### Supprimer le cluster

```powershell
minikube delete
```

## 📋 Vérification Complète

Une fois Minikube démarré, vérifiez que tout fonctionne :

```powershell
# 1. Statut de Minikube
minikube status

# 2. IP de Minikube
minikube ip

# 3. Contexte Kubernetes
kubectl get nodes

# 4. Services Kubernetes
kubectl get svc -A
```

## 🚀 Après le Démarrage

Une fois Minikube démarré, vous pouvez :

1. **Configurer l'Ingress** :
   ```powershell
   .\scripts\setup-ingress.ps1
   ```

2. **Déployer les services** :
   ```powershell
   kubectl apply -f k8s/
   ```

3. **Tester avec Postman** (voir `GUIDE-TEST-POSTMAN.md`)

## 🐛 Dépannage Avancé

### Problème : Minikube démarre mais ne répond pas

```powershell
# Redémarrer Minikube
minikube stop
minikube start

# Vérifier les logs
minikube logs
```

### Problème : Erreur de mémoire

Si Minikube manque de mémoire :

```powershell
# Allouer plus de mémoire (exemple : 4GB)
minikube start --memory=4096
```

### Problème : Erreur de CPU

Si Minikube manque de CPU :

```powershell
# Allouer plus de CPU (exemple : 2 CPUs)
minikube start --cpus=2
```

### Problème : Hyper-V n'est pas activé

Si Hyper-V n'est pas activé sur Windows :

1. Ouvrir PowerShell en tant qu'administrateur
2. Exécuter :
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
3. Redémarrer l'ordinateur
4. Réessayer `minikube start`

## 💡 Astuces

1. **Garder PowerShell ouvert** : Gardez la fenêtre PowerShell administrateur ouverte pendant que vous travaillez avec Minikube

2. **Vérifier Docker Desktop** : Si vous utilisez Docker Desktop, assurez-vous qu'il est démarré avant de lancer Minikube avec le driver Docker

3. **Allocation de ressources** : Par défaut, Minikube utilise 2 CPU et 2GB RAM. Vous pouvez ajuster selon vos besoins :
   ```powershell
   minikube start --cpus=4 --memory=4096
   ```

4. **Tunnel Minikube** : Si vous avez besoin d'accéder aux services depuis d'autres machines :
   ```powershell
   minikube tunnel
   ```

## 📚 Ressources

- [Documentation Minikube](https://minikube.sigs.k8s.io/docs/)
- [Minikube Drivers](https://minikube.sigs.k8s.io/docs/drivers/)
- [Hyper-V sur Windows](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/)

