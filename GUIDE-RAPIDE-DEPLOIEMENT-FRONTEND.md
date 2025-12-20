# Guide Rapide : Déployer le Frontend sur Kubernetes

## ✅ Étape 1 : Namespace Créé

Le namespace `smarthome` a été créé avec succès ! ✅

## 🚀 Étape 2 : Déployer le Frontend

### Option A : Déploiement Manuel (Recommandé pour commencer)

```powershell
# 1. Déployer le deployment
kubectl apply -f k8s/services/frontend/deployment.yaml

# 2. Déployer le service ClusterIP
kubectl apply -f k8s/services/frontend/service.yaml

# 3. (Optionnel) Déployer le service NodePort pour accès externe
kubectl apply -f k8s/services/frontend/service-nodeport.yaml
```

### Option B : Utiliser le Script de Déploiement Complet

```powershell
# Exécuter le script de configuration complète
.\scripts\setup-kubernetes-complet.ps1
```

## 🔍 Étape 3 : Vérifier le Déploiement

```powershell
# Vérifier que les pods sont en cours d'exécution
kubectl get pods -n smarthome -l app=frontend

# Vérifier que le service existe
kubectl get service frontend-service -n smarthome

# Vérifier les logs
kubectl logs -f deployment/frontend -n smarthome
```

## 🌐 Étape 4 : Accéder au Frontend

Une fois le frontend déployé, vous pouvez y accéder de plusieurs façons :

### Méthode 1 : Port-Forward (Le Plus Simple)

```powershell
kubectl port-forward service/frontend-service 3000:3000 -n smarthome
```

Puis ouvrez : **http://localhost:3000**

### Méthode 2 : NodePort (Si vous avez déployé le service NodePort)

```powershell
# Obtenir l'IP du cluster
minikube ip
# ou
kubectl get nodes -o wide
```

Puis ouvrez : **http://<IP>:30000**

### Méthode 3 : Ingress (Si configuré)

```powershell
# Activer l'Ingress (Minikube)
minikube addons enable ingress

# Obtenir l'IP
minikube ip
```

Ajoutez dans `C:\Windows\System32\drivers\etc\hosts` :
```
<IP> smarthome.local
```

Puis ouvrez : **http://smarthome.local/**

## ⚠️ Problèmes Courants

### Erreur : ImagePullBackOff

Si vous voyez cette erreur, cela signifie que Kubernetes ne peut pas télécharger l'image :

```powershell
# Vérifier que l'image existe sur Docker Hub
docker pull salmaidoufkir/frontend:latest

# Vérifier que le secret registry-secret existe
kubectl get secret registry-secret -n smarthome

# Si le secret n'existe pas, créez-le :
kubectl create secret docker-registry registry-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<VOTRE_USERNAME> \
  --docker-password=<VOTRE_PASSWORD> \
  --docker-email=<VOTRE_EMAIL> \
  -n smarthome
```

### Erreur : Pod en état Pending

```powershell
# Vérifier les détails du pod
kubectl describe pod -l app=frontend -n smarthome

# Vérifier les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp'
```

### Le Frontend ne Démarre pas

```powershell
# Vérifier les logs
kubectl logs -f deployment/frontend -n smarthome

# Vérifier les ressources disponibles
kubectl top nodes
kubectl top pods -n smarthome
```

## 📝 Commandes Utiles

```powershell
# Voir tous les services dans le namespace
kubectl get all -n smarthome

# Redémarrer le deployment
kubectl rollout restart deployment/frontend -n smarthome

# Supprimer le deployment (si besoin)
kubectl delete deployment frontend -n smarthome
kubectl delete service frontend-service -n smarthome
```

## 🔗 Ressources

- **Guide complet d'accès** : `GUIDE-COMPLET-ACCES-FRONTEND-KUBERNETES.md`
- **Guide de déploiement détaillé** : `GUIDE-DEPLOIEMENT-FRONTEND-KUBERNETES.md`

---

**Le namespace est prêt ! Vous pouvez maintenant déployer le frontend. 🚀**

