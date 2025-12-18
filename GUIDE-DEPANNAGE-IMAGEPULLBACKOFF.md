# Guide de Dépannage : Erreurs ImagePullBackOff

Ce guide vous aide à résoudre les erreurs `ImagePullBackOff` et `ErrImagePull` que vous rencontrez après avoir déployé les services Kubernetes.

## 🔴 Problème Identifié

Vous voyez ces erreurs :
```
ImagePullBackOff
ErrImagePull
```

Cela signifie que **Kubernetes ne peut pas télécharger les images Docker** depuis le registry `salmaidoufkir.com`.

## ✅ Solutions (dans l'ordre à essayer)

### Solution 1 : Vérifier le Secret Docker Registry

Le registry `salmaidoufkir.com` est privé, donc vous devez avoir un secret Kubernetes pour vous authentifier.

#### Étape 1.1 : Vérifier si le secret existe

```powershell
kubectl get secrets -n smarthome | findstr registry
```

Si vous ne voyez pas `registry-secret`, vous devez le créer.

#### Étape 1.2 : Créer le Secret Docker Registry

Vous devez créer le secret avec **vos identifiants** pour accéder au registry `salmaidoufkir.com` :

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

**Si vous n'avez pas d'accès au registry**, passez à la Solution 2.

#### Étape 1.3 : Vérifier que le secret est créé

```powershell
kubectl get secret registry-secret -n smarthome
kubectl describe secret registry-secret -n smarthome
```

#### Étape 1.4 : Redémarrer les déploiements

Après avoir créé le secret, redémarrez les déploiements :

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

#### Étape 1.5 : Vérifier que les pods démarrent

```powershell
kubectl get pods -n smarthome
```

Attendez 1-2 minutes et vérifiez à nouveau. Les pods devraient passer de `ImagePullBackOff` à `Running`.

---

### Solution 2 : Utiliser les Images Locales (si pas d'accès au registry)

Si vous n'avez pas accès au registry `salmaidoufkir.com`, vous devez construire les images localement et les utiliser dans Minikube.

#### Étape 2.1 : Activer l'Environnement Docker de Minikube

```powershell
minikube docker-env | Invoke-Expression
```

Cette commande configure votre terminal pour utiliser le Docker de Minikube.

#### Étape 2.2 : Construire les Images Localement

Construisez chaque image avec le même nom que dans les deployments :

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

#### Étape 2.3 : Vérifier que les Images sont Construites

```powershell
docker images | findstr salmaidoufkir
```

Vous devriez voir les 4 images.

#### Étape 2.4 : Modifier les Deployments pour Utiliser les Images Locales

**⚠️ IMPORTANT** : Vous devez modifier les deployments pour utiliser `imagePullPolicy: Never` au lieu de `Always`.

Pour chaque service, vous devez modifier le fichier de deployment temporairement :

**Option A : Via kubectl (sans modifier les fichiers)**

```powershell
# Usage Collector
kubectl set image deployment/usage-collector-service usage-collector-service=salmaidoufkir.com/usage-collector-service:latest -n smarthome
kubectl patch deployment usage-collector-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"usage-collector-service","imagePullPolicy":"Never"}]}}}}'

# Device Simulator
kubectl set image deployment/device-simulator-service device-simulator-service=salmaidoufkir.com/device-simulator-service:latest -n smarthome
kubectl patch deployment device-simulator-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"device-simulator-service","imagePullPolicy":"Never"}]}}}}'

# Optimizer
kubectl set image deployment/optimizer-service optimizer-service=salmaidoufkir.com/optimizer-service:latest -n smarthome
kubectl patch deployment optimizer-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"optimizer-service","imagePullPolicy":"Never"}]}}}}'

# Peak Detector
kubectl set image deployment/peak-detector-service peak-detector-service=salmaidoufkir.com/peak-detector-service:latest -n smarthome
kubectl patch deployment peak-detector-service -n smarthome -p '{"spec":{"template":{"spec":{"containers":[{"name":"peak-detector-service","imagePullPolicy":"Never"}]}}}}'
```

#### Étape 2.5 : Redémarrer les Déploiements

```powershell
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

#### Étape 2.6 : Vérifier que les Pods Démarrant

```powershell
kubectl get pods -n smarthome
```

Attendez 1-2 minutes. Les pods devraient maintenant démarrer.

---

### Solution 3 : Utiliser Docker Hub (Alternative)

Si vous avez publié les images sur Docker Hub, vous pouvez les utiliser :

```powershell
# Mettre à jour les images pour utiliser Docker Hub
kubectl set image deployment/usage-collector-service usage-collector-service=VOTRE_DOCKERHUB_USERNAME/usage-collector-service:latest -n smarthome
kubectl set image deployment/device-simulator-service device-simulator-service=VOTRE_DOCKERHUB_USERNAME/device-simulator-service:latest -n smarthome
kubectl set image deployment/optimizer-service optimizer-service=VOTRE_DOCKERHUB_USERNAME/optimizer-service:latest -n smarthome
kubectl set image deployment/peak-detector-service peak-detector-service=VOTRE_DOCKERHUB_USERNAME/peak-detector-service:latest -n smarthome
```

---

## 🔧 Dépannage RabbitMQ (CrashLoopBackOff)

Vous avez aussi un problème avec RabbitMQ qui est en `CrashLoopBackOff`.

### Vérifier les Logs de RabbitMQ

```powershell
kubectl logs -n smarthome -l app=rabbitmq --tail=100
```

### Causes Possibles

1. **Problème de secret** : RabbitMQ ne peut pas lire le secret `rabbitmq-secret`
2. **Problème de volume** : Le volume de stockage ne peut pas être créé
3. **Problème de configuration** : La configuration RabbitMQ est incorrecte

### Solutions

#### Solution 1 : Vérifier le Secret RabbitMQ

```powershell
kubectl get secret rabbitmq-secret -n smarthome
kubectl describe secret rabbitmq-secret -n smarthome
```

Si le secret n'existe pas, créez-le :

```powershell
kubectl create secret generic rabbitmq-secret `
  --from-literal=username=guest `
  --from-literal=password=guest123 `
  -n smarthome
```

#### Solution 2 : Vérifier les Logs Détaillés

```powershell
# Voir les logs du pod RabbitMQ
kubectl logs -n smarthome -l app=rabbitmq --tail=200

# Voir les détails du pod
kubectl describe pod -n smarthome -l app=rabbitmq
```

#### Solution 3 : Redémarrer RabbitMQ

```powershell
kubectl delete pod -n smarthome -l app=rabbitmq
```

Kubernetes créera automatiquement un nouveau pod.

---

## 📋 Checklist de Vérification

Après avoir appliqué une solution, vérifiez :

```powershell
# Voir l'état de tous les pods
kubectl get pods -n smarthome

# Voir les événements récents
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 20
```

### État Attendu

Tous les pods devraient être :
- **STATUS** : `Running`
- **READY** : `1/1` ou `2/2` (selon le nombre de conteneurs)

### Si les Pods sont Toujours en Erreur

1. **Vérifier les logs** :
   ```powershell
   kubectl logs -n smarthome <nom-du-pod> --tail=100
   ```

2. **Voir les détails du pod** :
   ```powershell
   kubectl describe pod <nom-du-pod> -n smarthome
   ```

3. **Vérifier les événements** :
   ```powershell
   kubectl get events -n smarthome --field-selector involvedObject.name=<nom-du-pod>
   ```

---

## 🚀 Commandes Utiles

### Nettoyer les Anciens Pods en Erreur

```powershell
# Supprimer tous les pods en erreur (ils seront recréés automatiquement)
kubectl delete pods -n smarthome --field-selector status.phase!=Running
```

### Voir l'Historique des Déploiements

```powershell
kubectl rollout history deployment/usage-collector-service -n smarthome
kubectl rollout history deployment/device-simulator-service -n smarthome
kubectl rollout history deployment/optimizer-service -n smarthome
kubectl rollout history deployment/peak-detector-service -n smarthome
```

### Revenir à une Version Précédente (si nécessaire)

```powershell
kubectl rollout undo deployment/usage-collector-service -n smarthome
```

---

## 📝 Résumé des Solutions

| Problème | Solution |
|----------|----------|
| `ImagePullBackOff` - Pas d'accès au registry | Solution 2 : Construire les images localement |
| `ImagePullBackOff` - Registry privé | Solution 1 : Créer le secret `registry-secret` |
| `CrashLoopBackOff` - RabbitMQ | Vérifier les secrets et les logs |

---

## ⚠️ Notes Importantes

1. **Ne modifiez pas les fichiers YAML** : Utilisez `kubectl` pour modifier les déploiements
2. **Les images doivent exister** : Soit dans le registry, soit construites localement
3. **Les secrets sont nécessaires** : Pour les registries privés et pour les services (PostgreSQL, RabbitMQ)
4. **Patience** : Les pods peuvent prendre 1-2 minutes pour démarrer après les corrections

---

## 🆘 Si Rien ne Fonctionne

1. **Vérifier que Minikube fonctionne** :
   ```powershell
   minikube status
   ```

2. **Vérifier que Docker fonctionne dans Minikube** :
   ```powershell
   minikube ssh
   docker ps
   exit
   ```

3. **Vérifier les ressources disponibles** :
   ```powershell
   kubectl top nodes
   kubectl top pods -n smarthome
   ```

4. **Redémarrer Minikube** (dernier recours) :
   ```powershell
   minikube stop
   minikube start
   ```

---

**Bon courage ! 🚀**

Si vous avez toujours des problèmes après avoir essayé toutes ces solutions, vérifiez les logs détaillés et partagez-les pour obtenir de l'aide supplémentaire.

