# Guide Complet : Installation et Configuration Kubernetes

Ce guide vous accompagne étape par étape pour configurer Kubernetes sur votre machine depuis le début, exactement comme votre collègue l'a fait.

## 📋 Table des Matières

1. [Prérequis](#1-prérequis)
2. [Installation des Outils](#2-installation-des-outils)
3. [Configuration de Minikube](#3-configuration-de-minikube)
4. [Création du Namespace](#4-création-du-namespace)
5. [Création des Secrets](#5-création-des-secrets)
6. [Déploiement des Bases de Données](#6-déploiement-des-bases-de-données)
7. [Déploiement du Message Broker](#7-déploiement-du-message-broker)
8. [Déploiement des Services](#8-déploiement-des-services)
9. [Configuration de l'Ingress](#9-configuration-de-lingress)
10. [Configuration du Fichier Hosts](#10-configuration-du-fichier-hosts)
11. [Vérification et Tests](#11-vérification-et-tests)
12. [Dépannage](#12-dépannage)

---

## 1. Prérequis

### Vérifications Initiales

Avant de commencer, vérifiez que vous avez :

- ✅ **Windows 10/11** (ou Windows Server)
- ✅ **Docker Desktop** installé et en cours d'exécution
- ✅ **Accès administrateur** à votre machine
- ✅ **Git** installé (pour cloner le projet)
- ✅ **Connexion Internet** (pour télécharger les outils et images Docker)

### Vérifier Docker Desktop

```powershell
# Vérifier que Docker fonctionne
docker --version
docker ps
```

Si Docker n'est pas installé, téléchargez-le depuis : https://www.docker.com/products/docker-desktop

---

## 2. Installation des Outils

### Étape 2.1 : Installer kubectl

**kubectl** est l'outil en ligne de commande pour interagir avec Kubernetes.

#### Option A : Via Chocolatey (Recommandé)

```powershell
# Ouvrir PowerShell en tant qu'administrateur
choco install kubernetes-cli
```

#### Option B : Installation Manuelle

1. Télécharger kubectl depuis : https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
2. Extraire `kubectl.exe` dans un dossier (ex: `C:\kubectl`)
3. Ajouter le dossier au PATH Windows

#### Vérifier l'Installation

```powershell
kubectl version --client
```

Vous devriez voir quelque chose comme :
```
Client Version: version.Info{Major:"1", Minor:"28", ...}
```

### Étape 2.2 : Installer Minikube

**Minikube** permet de créer un cluster Kubernetes local.

#### Option A : Via Chocolatey

```powershell
# Ouvrir PowerShell en tant qu'administrateur
choco install minikube
```

#### Option B : Installation Manuelle

1. Télécharger depuis : https://minikube.sigs.k8s.io/docs/start/
2. Exécuter le fichier `.exe` téléchargé
3. Suivre l'assistant d'installation

#### Vérifier l'Installation

```powershell
minikube version
```

---

## 3. Configuration de Minikube

### Étape 3.1 : Cloner le Projet

```powershell
# Naviguer vers votre dossier de travail
cd D:\

# Cloner le projet (remplacez par l'URL de votre repo)
git clone <URL_DU_REPO> smart-home-load-balancer

# Naviguer dans le projet
cd smart-home-load-balancer
```

### Étape 3.2 : Démarrer Minikube

**⚠️ IMPORTANT : Ouvrir PowerShell en tant qu'administrateur**

1. **Fermer PowerShell actuel**
2. **Clic droit sur PowerShell** → "Exécuter en tant qu'administrateur"
3. **Naviguer vers le projet** :
   ```powershell
   cd D:\smart-home-load-balancer
   ```

4. **Démarrer Minikube** :
   ```powershell
   minikube start
   ```

**Temps d'attente** : 2-5 minutes la première fois (téléchargement de l'image)

#### Si Erreur de Permissions Hyper-V

Si vous obtenez l'erreur `Hyper-V requires Administrator privileges` :

1. Assurez-vous que PowerShell est ouvert **en tant qu'administrateur**
2. Ou utilisez Docker Desktop comme driver :
   ```powershell
   minikube start --driver=docker
   ```

### Étape 3.3 : Vérifier Minikube

```powershell
# Vérifier le statut
minikube status

# Vérifier les nodes Kubernetes
kubectl get nodes

# Obtenir l'IP de Minikube
minikube ip
```

Vous devriez voir :
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Étape 3.4 : Configurer kubectl pour Minikube

Minikube configure automatiquement kubectl. Vérifiez :

```powershell
kubectl config current-context
```

Vous devriez voir : `minikube`

---

## 4. Création du Namespace

### Étape 4.1 : Créer le Namespace smarthome

```powershell
# Appliquer le fichier de namespace
kubectl apply -f k8s/namespaces/smarthome-namespace.yaml
```

### Étape 4.2 : Vérifier

```powershell
kubectl get namespaces
```

Vous devriez voir `smarthome` dans la liste.

---

## 5. Création des Secrets

Les secrets Kubernetes stockent les informations sensibles (mots de passe, clés, etc.).

### Étape 5.1 : Créer le Secret PostgreSQL

```powershell
kubectl create secret generic postgres-secret `
  --from-literal=username=smarthome `
  --from-literal=password=smarthome123 `
  --from-literal=database=smarthome `
  -n smarthome
```

**⚠️ Remplacez `smarthome123` par un mot de passe sécurisé de votre choix.**

### Étape 5.2 : Créer le Secret RabbitMQ

```powershell
kubectl create secret generic rabbitmq-secret `
  --from-literal=username=guest `
  --from-literal=password=guest123 `
  -n smarthome
```

**⚠️ Remplacez `guest123` par un mot de passe sécurisé de votre choix.**

### Étape 5.3 : Créer le Secret MongoDB (optionnel)

```powershell
kubectl create secret generic mongodb-secret `
  --from-literal=username=admin `
  --from-literal=password=admin123 `
  -n smarthome
```

### Étape 5.4 : Créer le Secret Docker Registry

Si vous utilisez un registry Docker privé (comme `salmaidoufkir.com`) :

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=salmaidoufkir.com `
  --docker-username=VOTRE_USERNAME `
  --docker-password=VOTRE_PASSWORD `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

**⚠️ Remplacez les valeurs par vos identifiants réels.**

### Étape 5.5 : Vérifier les Secrets

```powershell
kubectl get secrets -n smarthome
```

Vous devriez voir :
- `postgres-secret`
- `rabbitmq-secret`
- `mongodb-secret` (si créé)
- `registry-secret` (si créé)

---

## 6. Déploiement des Bases de Données

### Étape 6.1 : Déployer PostgreSQL

```powershell
# Déployer PostgreSQL
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml
```

### Étape 6.2 : Vérifier PostgreSQL

```powershell
# Vérifier le déploiement
kubectl get pods -n smarthome | findstr postgres

# Vérifier que le pod est prêt (STATUS = Running, READY = 1/1)
kubectl get pods -n smarthome -l app=postgres

# Voir les logs
kubectl logs -n smarthome -l app=postgres --tail=50
```

**Attendez que le pod soit en état `Running` et `1/1` avant de continuer.**

### Étape 6.3 : Déployer MongoDB (optionnel)

```powershell
kubectl apply -f k8s/databases/mongodb-deployment.yaml
kubectl apply -f k8s/databases/mongodb-service.yaml
```

---

## 7. Déploiement du Message Broker

### Étape 7.1 : Déployer RabbitMQ

```powershell
# Déployer RabbitMQ
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml
```

### Étape 7.2 : Vérifier RabbitMQ

```powershell
# Vérifier le déploiement
kubectl get pods -n smarthome | findstr rabbitmq

# Vérifier que le pod est prêt
kubectl get pods -n smarthome -l app=rabbitmq

# Voir les logs
kubectl logs -n smarthome -l app=rabbitmq --tail=50
```

**Attendez que le pod soit en état `Running` et `1/1` avant de continuer.**

---

## 8. Déploiement des Services

### Étape 8.1 : Préparer les Images Docker

Les services utilisent des images Docker. Vous avez deux options :

#### Option A : Utiliser les Images du Registry (si disponibles)

Si les images sont déjà publiées sur `salmaidoufkir.com`, elles seront téléchargées automatiquement.

#### Option B : Construire les Images Localement

Si vous devez construire les images localement :

```powershell
# Activer l'environnement Docker de Minikube
minikube docker-env | Invoke-Expression

# Construire les images
cd usage-collector-service
docker build -t salmaidoufkir/usage-collector-service:latest .
cd ..

cd peak-detector-service
docker build -t salmaidoufkir/peak-detector-service:latest .
cd ..

cd optimizer-service
docker build -t salmaidoufkir/optimizer-service:latest .
cd ..

cd device-simulator-service
docker build -t salmaidoufkir/device-simulator-service:latest .
cd ..
```

### Étape 8.2 : Déployer Usage Collector Service

```powershell
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/usage-collector/service.yaml
```

### Étape 8.3 : Déployer Peak Detector Service

```powershell
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/service.yaml
```

### Étape 8.4 : Déployer Optimizer Service

```powershell
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/optimizer/service.yaml
```

### Étape 8.5 : Déployer Device Simulator Service

```powershell
kubectl apply -f k8s/services/device-simulator/deployment.yaml
kubectl apply -f k8s/services/device-simulator/service.yaml
```

### Étape 8.6 : Vérifier tous les Services

```powershell
# Voir tous les pods
kubectl get pods -n smarthome

# Voir tous les services
kubectl get svc -n smarthome

# Vérifier les logs d'un service spécifique
kubectl logs -n smarthome -l app=usage-collector-service --tail=50
```

**Attendez que tous les pods soient en état `Running` et `READY` avant de continuer.**

---

## 9. Configuration de l'Ingress

L'Ingress permet d'exposer les services à l'extérieur du cluster.

### Étape 9.1 : Activer l'Ingress Controller dans Minikube

```powershell
minikube addons enable ingress
```

**Temps d'attente** : 1-2 minutes

### Étape 9.2 : Vérifier l'Ingress Controller

```powershell
kubectl get pods -n ingress-nginx
```

Vous devriez voir des pods `ingress-nginx-controller` en cours d'exécution.

### Étape 9.3 : Appliquer la Configuration Ingress

```powershell
kubectl apply -f k8s/ingress/ingress.yaml
```

### Étape 9.4 : Vérifier l'Ingress

```powershell
# Vérifier l'Ingress
kubectl get ingress -n smarthome

# Voir les détails
kubectl describe ingress smarthome-ingress -n smarthome
```

---

## 10. Configuration du Fichier Hosts

Pour accéder aux services via `smarthome.local`, vous devez configurer le fichier hosts.

### Étape 10.1 : Obtenir l'IP de Minikube

```powershell
minikube ip
```

Notez l'IP (ex: `192.168.49.2`)

### Étape 10.2 : Modifier le Fichier Hosts

1. **Ouvrir le Bloc-notes en tant qu'administrateur** :
   - Rechercher "Bloc-notes" dans le menu Démarrer
   - Clic droit → "Exécuter en tant qu'administrateur"

2. **Ouvrir le fichier hosts** :
   - Fichier → Ouvrir
   - Naviguer vers : `C:\Windows\System32\drivers\etc\`
   - Changer le filtre de "Documents texte" à "Tous les fichiers"
   - Ouvrir `hosts`

3. **Ajouter cette ligne** (remplacez `192.168.49.2` par votre IP Minikube) :
   ```
   192.168.49.2 smarthome.local
   ```

4. **Sauvegarder** le fichier

### Étape 10.3 : Vérifier

```powershell
# Tester la résolution DNS
ping smarthome.local
```

Vous devriez voir des réponses de l'IP de Minikube.

---

## 11. Vérification et Tests

### Étape 11.1 : Vérifier l'État Global

```powershell
# Voir tous les pods
kubectl get pods -n smarthome

# Voir tous les services
kubectl get svc -n smarthome

# Voir l'Ingress
kubectl get ingress -n smarthome
```

Tous les pods doivent être en état `Running` et `READY`.

### Étape 11.2 : Tester avec Postman

Ouvrez Postman et testez les endpoints :

#### Test 1 : Usage Collector - Consommation Actuelle
```
GET http://smarthome.local/usage/current
```

#### Test 2 : Usage Collector - Historique
```
GET http://smarthome.local/usage/history?limit=10
```

#### Test 3 : Optimizer - Health Check
```
GET http://smarthome.local/optimizer/health
```

#### Test 4 : Device Simulator - Liste des Appareils
```
GET http://smarthome.local/devices/devices
```

#### Test 5 : Usage Collector - Sauvegarder un Snapshot
```
POST http://smarthome.local/usage/save
```

### Étape 11.3 : Vérifier les Logs

Si un service ne fonctionne pas, vérifiez les logs :

```powershell
# Logs d'un service spécifique
kubectl logs -n smarthome -l app=usage-collector-service --tail=100

# Logs en temps réel
kubectl logs -n smarthome -l app=usage-collector-service -f
```

---

## 12. Dépannage

### Problème : Minikube ne démarre pas

**Solution** :
1. Vérifier que PowerShell est ouvert en tant qu'administrateur
2. Vérifier que Docker Desktop est en cours d'exécution
3. Essayer avec un autre driver : `minikube start --driver=docker`

### Problème : Les pods restent en état "Pending"

**Solution** :
```powershell
# Voir pourquoi un pod est en Pending
kubectl describe pod <nom-du-pod> -n smarthome

# Vérifier les ressources disponibles
kubectl top nodes
```

### Problème : Les pods sont en état "ImagePullBackOff"

**Solution** :
1. Vérifier que les images Docker existent
2. Si vous utilisez un registry privé, vérifier que le secret `registry-secret` est créé
3. Construire les images localement si nécessaire

### Problème : Erreur "Connection refused" dans Postman

**Solution** :
1. Vérifier que l'Ingress est actif : `kubectl get ingress -n smarthome`
2. Vérifier que le fichier hosts est correctement configuré
3. Vérifier l'IP de Minikube : `minikube ip`
4. Vérifier que les services sont en cours d'exécution : `kubectl get pods -n smarthome`

### Problème : Les services ne peuvent pas se connecter à PostgreSQL/RabbitMQ

**Solution** :
1. Vérifier que PostgreSQL/RabbitMQ sont en cours d'exécution
2. Vérifier les secrets : `kubectl get secrets -n smarthome`
3. Vérifier les logs des services pour voir les erreurs de connexion

### Problème : Erreur "namespace smarthome not found"

**Solution** :
```powershell
# Créer le namespace
kubectl apply -f k8s/namespaces/smarthome-namespace.yaml
```

---

## 📚 Commandes Utiles

### Voir l'État de Tous les Ressources

```powershell
# Tous les pods
kubectl get pods -n smarthome

# Tous les services
kubectl get svc -n smarthome

# Tous les deployments
kubectl get deployments -n smarthome

# Tous les secrets
kubectl get secrets -n smarthome
```

### Redémarrer un Service

```powershell
# Redémarrer un deployment
kubectl rollout restart deployment/usage-collector-service -n smarthome
```

### Supprimer et Recréer

```powershell
# Supprimer un deployment
kubectl delete deployment usage-collector-service -n smarthome

# Recréer
kubectl apply -f k8s/services/usage-collector/deployment.yaml
```

### Accéder à un Pod (Debug)

```powershell
# Ouvrir un shell dans un pod
kubectl exec -it <nom-du-pod> -n smarthome -- /bin/bash
```

### Port Forward (Alternative à l'Ingress)

Si l'Ingress ne fonctionne pas, vous pouvez utiliser port-forward :

```powershell
# Usage Collector
kubectl port-forward svc/usage-collector-service 8083:8083 -n smarthome

# Dans un autre terminal, tester :
# GET http://localhost:8083/usage/current
```

---

## ✅ Checklist de Vérification

Avant de considérer que tout est configuré, vérifiez :

- [ ] Minikube est démarré et fonctionne
- [ ] Le namespace `smarthome` existe
- [ ] Tous les secrets sont créés
- [ ] PostgreSQL est déployé et en cours d'exécution
- [ ] RabbitMQ est déployé et en cours d'exécution
- [ ] Tous les services sont déployés et en cours d'exécution
- [ ] L'Ingress est configuré et actif
- [ ] Le fichier hosts est configuré
- [ ] Les tests Postman fonctionnent

---

## 🎉 Félicitations !

Si tous les tests Postman fonctionnent, votre configuration Kubernetes est complète et opérationnelle !

Pour plus d'informations, consultez :
- `GUIDE-TEST-POSTMAN.md` - Guide détaillé pour tester avec Postman
- `GUIDE-DEMARRER-MINIKUBE.md` - Guide pour démarrer Minikube
- `k8s/secrets/README.md` - Documentation sur les secrets

