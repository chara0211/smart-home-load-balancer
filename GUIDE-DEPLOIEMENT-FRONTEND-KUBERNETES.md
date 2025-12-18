# Guide : Déploiement du Frontend sur Kubernetes

Ce guide explique comment construire, pousser et déployer le frontend Next.js sur Kubernetes.

## 📋 Prérequis

- Docker installé et en cours d'exécution
- Compte Docker Hub (ou accès au registry Docker)
- kubectl configuré pour accéder à votre cluster Kubernetes

## 🚀 Étape 1 : Construire l'image Docker

Depuis le répertoire racine du projet :

```bash
cd frontend
docker build -t salmaidoufkir/frontend:latest .
```

Ou depuis le répertoire racine :

```bash
docker build -t salmaidoufkir/frontend:latest ./frontend
```

## 📤 Étape 2 : Pousser l'image sur Docker Hub

```bash
# Se connecter à Docker Hub (si pas déjà connecté)
docker login

# Pousser l'image
docker push salmaidoufkir/frontend:latest
```

**Note** : Assurez-vous que votre image est publique sur Docker Hub, ou que vous avez configuré le secret `registry-secret` dans Kubernetes.

## ☸️ Étape 3 : Déployer sur Kubernetes

### Option A : Déploiement complet (recommandé)

Utilisez le script de déploiement qui inclut maintenant le frontend :

```bash
# Script bash
./scripts/deploy-all.sh

# Ou script PowerShell
.\scripts\setup-kubernetes-complet.ps1
```

### Option B : Déploiement manuel

```bash
# Déployer le frontend
kubectl apply -f k8s/services/frontend/deployment.yaml
kubectl apply -f k8s/services/frontend/service.yaml
kubectl apply -f k8s/services/frontend/hpa.yaml

# Mettre à jour l'ingress (si pas déjà fait)
kubectl apply -f k8s/ingress/ingress.yaml
```

## 🔍 Vérification

### Vérifier que les pods sont en cours d'exécution

```bash
kubectl get pods -n smarthome -l app=frontend
```

Vous devriez voir 2 pods (réplicas) en état `Running`.

### Vérifier les logs

```bash
kubectl logs -f deployment/frontend -n smarthome
```

### Vérifier le service

```bash
kubectl get service frontend-service -n smarthome
```

### Accéder au frontend

Selon votre configuration Ingress :

- **Via Ingress** : http://smarthome.local/ (ou votre domaine)
- **Via Port Forward** (pour tester) :
  ```bash
  kubectl port-forward service/frontend-service 3000:3000 -n smarthome
  ```
  Puis accéder à : http://localhost:3000

## 🔧 Configuration

### Variables d'environnement

Le frontend utilise la variable d'environnement `NEXT_PUBLIC_BACKEND_URL` pour se connecter au service backend. Elle est configurée dans le deployment pour pointer vers `http://usage-collector-service:8083`.

### Mise à jour de l'image

Si vous modifiez le code du frontend :

```bash
# 1. Reconstruire l'image
docker build -t salmaidoufkir/frontend:latest ./frontend

# 2. Pousser la nouvelle image
docker push salmaidoufkir/frontend:latest

# 3. Redémarrer le deployment pour forcer le pull de la nouvelle image
kubectl rollout restart deployment/frontend -n smarthome
```

## 🐛 Dépannage

### Les pods ne démarrent pas

1. Vérifier les logs :
   ```bash
   kubectl logs -f deployment/frontend -n smarthome
   ```

2. Vérifier les événements :
   ```bash
   kubectl describe pod -l app=frontend -n smarthome
   ```

3. Vérifier que l'image existe :
   ```bash
   docker pull salmaidoufkir/frontend:latest
   ```

### Erreur ImagePullBackOff

Si vous voyez cette erreur, cela signifie que Kubernetes ne peut pas télécharger l'image :

1. Vérifier que l'image est publique sur Docker Hub, ou
2. Vérifier que le secret `registry-secret` est configuré :
   ```bash
   kubectl get secret registry-secret -n smarthome
   ```

### Le frontend ne peut pas se connecter au backend

1. Vérifier que le service `usage-collector-service` est en cours d'exécution :
   ```bash
   kubectl get pods -n smarthome -l app=usage-collector-service
   ```

2. Vérifier la variable d'environnement dans le deployment :
   ```bash
   kubectl get deployment frontend -n smarthome -o yaml | grep NEXT_PUBLIC_BACKEND_URL
   ```

## 📝 Notes

- Le frontend utilise le mode `standalone` de Next.js pour une image Docker optimisée
- Le frontend est configuré pour utiliser le proxy Next.js qui redirige `/api/*` vers le service backend
- L'ingress est configuré pour servir le frontend à la racine `/` (en dernier dans la liste des chemins)
- Le HPA (Horizontal Pod Autoscaler) est configuré pour auto-scaling entre 2 et 5 réplicas

