# Guide : Configuration Kubernetes Après le Pull

Ce guide explique **exactement ce que vous devez faire** après avoir pullé les changements Kubernetes de votre collègue.

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ **Git** installé
- ✅ **Docker Desktop** installé et en cours d'exécution
- ✅ **kubectl** installé
- ✅ **Minikube** installé
- ✅ **Accès administrateur** à votre machine

Si vous n'avez pas ces outils, consultez d'abord : `GUIDE-INSTALLATION-KUBERNETES-COMPLET.md` (section Installation des Outils)

---

## 🚀 Étapes à Suivre

### Étape 1 : Récupérer les Changements

```powershell
# Naviguer vers le projet
cd D:\smart-home-load-balancer

# Récupérer les dernières modifications
git pull origin <nom-de-la-branche>

# Vérifier que les fichiers Kubernetes sont présents
ls k8s/
```

Vous devriez voir les dossiers :
- `k8s/namespaces/`
- `k8s/secrets/`
- `k8s/databases/`
- `k8s/message-broker/`
- `k8s/services/`
- `k8s/ingress/`

---

### Étape 2 : Démarrer Minikube

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

   **Si erreur de permissions Hyper-V** :
   ```powershell
   minikube start --driver=docker
   ```

5. **Vérifier que Minikube fonctionne** :
   ```powershell
   minikube status
   minikube ip
   ```

---

### Étape 3 : Créer le Namespace

```powershell
kubectl apply -f k8s/namespaces/smarthome-namespace.yaml
```

**Vérifier** :
```powershell
kubectl get namespaces | findstr smarthome
```

---

### Étape 4 : Créer les Secrets Kubernetes

Les secrets stockent les mots de passe et identifiants. **Vous devez les créer avec vos propres valeurs**.

#### 4.1 : Secret PostgreSQL

```powershell
kubectl create secret generic postgres-secret `
  --from-literal=username=smarthome `
  --from-literal=password=VOTRE_MOT_DE_PASSE_POSTGRES `
  --from-literal=database=smarthome `
  -n smarthome
```

**⚠️ Remplacez `VOTRE_MOT_DE_PASSE_POSTGRES` par un mot de passe sécurisé de votre choix.**

#### 4.2 : Secret RabbitMQ

```powershell
kubectl create secret generic rabbitmq-secret `
  --from-literal=username=guest `
  --from-literal=password=VOTRE_MOT_DE_PASSE_RABBITMQ `
  -n smarthome
```

**⚠️ Remplacez `VOTRE_MOT_DE_PASSE_RABBITMQ` par un mot de passe sécurisé de votre choix.**

#### 4.3 : Secret Docker Registry (si vous utilisez un registry privé)

Si les images Docker sont sur un registry privé (comme `salmaidoufkir.com`), créez ce secret :

```powershell
kubectl create secret docker-registry registry-secret `
  --docker-server=salmaidoufkir.com `
  --docker-username=VOTRE_USERNAME `
  --docker-password=VOTRE_PASSWORD `
  --docker-email=VOTRE_EMAIL `
  -n smarthome
```

**⚠️ Remplacez les valeurs par vos identifiants réels.**

#### 4.4 : Vérifier les Secrets

```powershell
kubectl get secrets -n smarthome
```

Vous devriez voir au minimum :
- `postgres-secret`
- `rabbitmq-secret`
- `registry-secret` (si créé)

---

### Étape 5 : Déployer les Bases de Données

#### 5.1 : Déployer PostgreSQL

```powershell
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml
```

**Vérifier que PostgreSQL démarre** :
```powershell
kubectl get pods -n smarthome -l app=postgres
```

**Attendre que le pod soit en état `Running` et `READY 1/1`** (peut prendre 1-2 minutes).

#### 5.2 : Vérifier les Logs (si nécessaire)

```powershell
kubectl logs -n smarthome -l app=postgres --tail=50
```

---

### Étape 6 : Déployer RabbitMQ

```powershell
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml
```

**Vérifier que RabbitMQ démarre** :
```powershell
kubectl get pods -n smarthome -l app=rabbitmq
```

**Attendre que le pod soit en état `Running` et `READY 1/1`** (peut prendre 1-2 minutes).

---

### Étape 7 : Déployer les Services Microservices

Déployez les services dans l'ordre suivant :

#### 7.1 : Usage Collector Service

```powershell
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/usage-collector/service.yaml
```

#### 7.2 : Peak Detector Service

```powershell
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/service.yaml
```

#### 7.3 : Optimizer Service

```powershell
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/optimizer/service.yaml
```

#### 7.4 : Device Simulator Service

```powershell
kubectl apply -f k8s/services/device-simulator/deployment.yaml
kubectl apply -f k8s/services/device-simulator/service.yaml
```

#### 7.5 : Vérifier tous les Services

```powershell
kubectl get pods -n smarthome
```

**Tous les pods doivent être en état `Running` et `READY`.**

**Si un pod est en erreur**, voir les logs :
```powershell
kubectl logs -n smarthome -l app=usage-collector-service --tail=100
```

---

### Étape 8 : Configurer l'Ingress

L'Ingress permet d'exposer les services à l'extérieur du cluster.

#### 8.1 : Activer l'Ingress Controller dans Minikube

```powershell
minikube addons enable ingress
```

**Attendre 1-2 minutes** que l'Ingress Controller démarre.

#### 8.2 : Vérifier l'Ingress Controller

```powershell
kubectl get pods -n ingress-nginx
```

Vous devriez voir des pods `ingress-nginx-controller` en cours d'exécution.

#### 8.3 : Appliquer la Configuration Ingress

```powershell
kubectl apply -f k8s/ingress/ingress.yaml
```

#### 8.4 : Vérifier l'Ingress

```powershell
kubectl get ingress -n smarthome
```

---

### Étape 9 : Configurer le Fichier Hosts

Pour accéder aux services via `smarthome.local`, vous devez configurer le fichier hosts.

#### 9.1 : Obtenir l'IP de Minikube

```powershell
minikube ip
```

Notez l'IP (exemple : `192.168.49.2`)

#### 9.2 : Modifier le Fichier Hosts

1. **Ouvrir le Bloc-notes en tant qu'administrateur** :
   - Rechercher "Bloc-notes" dans le menu Démarrer
   - **Clic droit** → "Exécuter en tant qu'administrateur"

2. **Ouvrir le fichier hosts** :
   - Fichier → Ouvrir
   - Naviguer vers : `C:\Windows\System32\drivers\etc\`
   - Changer le filtre de "Documents texte" à **"Tous les fichiers"**
   - Ouvrir `hosts`

3. **Ajouter cette ligne** (remplacez `192.168.49.2` par votre IP Minikube) :
   ```
   192.168.49.2 smarthome.local
   ```

4. **Sauvegarder** le fichier

#### 9.3 : Vérifier

```powershell
ping smarthome.local
```

Vous devriez voir des réponses de l'IP de Minikube.

---

### Étape 10 : Vérifier que Tout Fonctionne

#### 10.1 : Vérifier l'État Global

```powershell
# Voir tous les pods
kubectl get pods -n smarthome

# Voir tous les services
kubectl get svc -n smarthome

# Voir l'Ingress
kubectl get ingress -n smarthome
```

**Tous les pods doivent être en état `Running` et `READY`.**

#### 10.2 : Utiliser le Script de Vérification (Optionnel)

```powershell
.\scripts\verifier-configuration.ps1
```

Ce script vérifie automatiquement tous les composants.

---

### Étape 11 : Tester avec Postman

Ouvrez Postman et testez les endpoints :

#### Test 1 : Usage Collector - Consommation Actuelle
```
GET http://smarthome.local/usage/current
```

#### Test 2 : Optimizer - Health Check
```
GET http://smarthome.local/optimizer/health
```

#### Test 3 : Device Simulator - Liste des Appareils
```
GET http://smarthome.local/devices/devices
```

#### Test 4 : Usage Collector - Sauvegarder un Snapshot
```
POST http://smarthome.local/usage/save
```

**Si les tests fonctionnent, votre configuration est complète ! ✅**

---

## 🐛 Dépannage

### ⚠️ Erreurs ImagePullBackOff ou ErrImagePull

Si vous voyez ces erreurs :
```
ImagePullBackOff
ErrImagePull
```

👉 **Consultez le guide détaillé** : **[GUIDE-DEPANNAGE-IMAGEPULLBACKOFF.md](GUIDE-DEPANNAGE-IMAGEPULLBACKOFF.md)**

Ce guide explique comment résoudre les problèmes de téléchargement d'images Docker.

### Problème : Les pods restent en état "Pending"

**Solution** :
```powershell
# Voir pourquoi un pod est en Pending
kubectl describe pod <nom-du-pod> -n smarthome
```

### Problème : Erreur "ImagePullBackOff"

**Causes possibles** :
1. Les images Docker n'existent pas dans le registry
2. Le secret `registry-secret` n'est pas créé (si registry privé)

**Solutions** :
- Si vous utilisez un registry privé, vérifiez que le secret `registry-secret` est créé
- Si les images n'existent pas, vous devez les construire ou les publier

### Problème : Erreur "Connection refused" dans Postman

**Vérifications** :
1. L'Ingress est actif : `kubectl get ingress -n smarthome`
2. Le fichier hosts est correctement configuré
3. L'IP de Minikube correspond à celle dans hosts : `minikube ip`
4. Les services sont en cours d'exécution : `kubectl get pods -n smarthome`

### Problème : Les services ne peuvent pas se connecter à PostgreSQL/RabbitMQ

**Vérifications** :
1. PostgreSQL/RabbitMQ sont en cours d'exécution : `kubectl get pods -n smarthome`
2. Les secrets sont créés : `kubectl get secrets -n smarthome`
3. Vérifier les logs des services : `kubectl logs -n smarthome -l app=usage-collector-service`

---

## 📝 Checklist de Vérification

Avant de considérer que tout est configuré, vérifiez :

- [ ] Minikube est démarré (`minikube status`)
- [ ] Le namespace `smarthome` existe (`kubectl get namespaces`)
- [ ] Tous les secrets sont créés (`kubectl get secrets -n smarthome`)
- [ ] PostgreSQL est en cours d'exécution (`kubectl get pods -n smarthome | findstr postgres`)
- [ ] RabbitMQ est en cours d'exécution (`kubectl get pods -n smarthome | findstr rabbitmq`)
- [ ] Tous les services sont en cours d'exécution (`kubectl get pods -n smarthome`)
- [ ] L'Ingress est configuré (`kubectl get ingress -n smarthome`)
- [ ] Le fichier hosts est configuré
- [ ] Les tests Postman fonctionnent

---

## 🚀 Script Automatique (Alternative)

Si vous préférez automatiser la plupart des étapes, vous pouvez utiliser le script :

```powershell
# Ouvrir PowerShell en tant qu'administrateur
.\scripts\setup-kubernetes-complet.ps1
```

**Note** : Le script automatise les étapes 2 à 8, mais vous devrez toujours :
- Créer les secrets avec vos propres mots de passe (étape 4)
- Configurer le fichier hosts manuellement (étape 9)

---

## 📚 Ressources Supplémentaires

- **Guide complet d'installation** : `GUIDE-INSTALLATION-KUBERNETES-COMPLET.md`
- **Guide de test Postman** : `GUIDE-TEST-POSTMAN.md`
- **Guide de démarrage Minikube** : `GUIDE-DEMARRER-MINIKUBE.md`
- **Documentation des secrets** : `k8s/secrets/README.md`

---

## ✅ Résumé des Commandes Essentielles

```powershell
# Démarrer Minikube
minikube start

# Créer le namespace
kubectl apply -f k8s/namespaces/smarthome-namespace.yaml

# Créer les secrets (avec vos propres mots de passe)
kubectl create secret generic postgres-secret --from-literal=username=smarthome --from-literal=password=VOTRE_MDP --from-literal=database=smarthome -n smarthome
kubectl create secret generic rabbitmq-secret --from-literal=username=guest --from-literal=password=VOTRE_MDP -n smarthome

# Déployer les bases de données
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml

# Déployer les services
kubectl apply -f k8s/services/usage-collector/
kubectl apply -f k8s/services/peak-detector/
kubectl apply -f k8s/services/optimizer/
kubectl apply -f k8s/services/device-simulator/

# Configurer l'Ingress
minikube addons enable ingress
kubectl apply -f k8s/ingress/ingress.yaml

# Configurer le fichier hosts (manuellement)
# Ajouter : <IP_MINIKUBE> smarthome.local dans C:\Windows\System32\drivers\etc\hosts
```

---

**Bon courage ! 🚀**

Si vous rencontrez des problèmes, consultez la section Dépannage ou les guides détaillés mentionnés ci-dessus.

