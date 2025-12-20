# Guide Complet : Accéder au Frontend Déployé sur Kubernetes

Ce guide récapitule **toutes les méthodes** pour accéder à votre frontend Next.js déployé sur Kubernetes.

---

## 🔍 Vérification Préalable

Avant d'accéder au frontend, vérifiez qu'il est bien déployé :

```powershell
# Vérifier que les pods sont en cours d'exécution
kubectl get pods -n smarthome -l app=frontend

# Vérifier que le service existe
kubectl get service frontend-service -n smarthome

# Vérifier l'état du deployment
kubectl get deployment frontend -n smarthome
```

Vous devriez voir :
- **Pods** : 1 pod (ou plus) en état `Running`
- **Service** : Un service `frontend-service` de type `ClusterIP` ou `NodePort`
- **Deployment** : Le deployment `frontend` avec le nombre de réplicas souhaité

---

## 🚀 Méthode 1 : Port-Forward (La Plus Simple - RECOMMANDÉE pour Tester)

**La méthode la plus rapide pour tester localement.**

### Étape 1 : Créer le port-forward

```powershell
kubectl port-forward service/frontend-service 3000:3000 -n smarthome
```

### Étape 2 : Accéder au frontend

Ouvrez votre navigateur et allez sur :
```
http://localhost:3000
```

**✅ Avantages :**
- ✅ Fonctionne immédiatement
- ✅ Pas de configuration supplémentaire
- ✅ Parfait pour le développement/test
- ✅ Pas besoin de modifier les fichiers hosts

**⚠️ Inconvénients :**
- ❌ Le port-forward doit rester actif (terminal ouvert)
- ❌ Arrête si vous fermez le terminal
- ❌ Un seul utilisateur à la fois

**💡 Astuce :** Pour garder le port-forward actif en arrière-plan, utilisez :
```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/frontend-service 3000:3000 -n smarthome"
```

---

## 🌐 Méthode 2 : Via NodePort (Accès Direct Permanent)

**Méthode recommandée pour un accès permanent sans garder un terminal ouvert.**

### Étape 1 : Vérifier si le service NodePort existe

```powershell
kubectl get service frontend-service-nodeport -n smarthome
```

Si le service n'existe pas, créez-le :

```powershell
kubectl apply -f k8s/services/frontend/service-nodeport.yaml
```

### Étape 2 : Obtenir l'IP du cluster

```powershell
# Si vous utilisez Minikube
minikube ip

# Sinon, obtenez l'IP d'un node
kubectl get nodes -o wide
```

Vous obtiendrez une IP, par exemple : `192.168.49.2` ou `172.30.95.94`

### Étape 3 : Accéder au frontend

Ouvrez votre navigateur et allez sur :
```
http://<IP-DU-CLUSTER>:30000
```

Exemples :
- `http://192.168.49.2:30000` (Minikube)
- `http://172.30.95.94:30000` (Autre cluster)

**✅ Avantages :**
- ✅ Accès direct via l'IP
- ✅ Pas besoin de garder un terminal ouvert
- ✅ Permanent
- ✅ Accessible depuis n'importe quelle machine sur le réseau

**⚠️ Inconvénients :**
- ❌ Nécessite de connaître l'IP du cluster
- ❌ L'IP peut changer si le cluster est recréé

**📝 Configuration du Service NodePort :**

Le service NodePort est défini dans `k8s/services/frontend/service-nodeport.yaml` :
- **Port du service** : `3000`
- **Port du conteneur** : `3000`
- **NodePort** : `30000` (port externe accessible)

---

## 🎯 Méthode 3 : Via Ingress (Configuration Production-like)

**Méthode recommandée pour un environnement de production.**

### Étape 1 : Vérifier que l'Ingress Controller est activé

```powershell
# Si vous utilisez Minikube
minikube addons enable ingress

# Vérifier que l'Ingress Controller est actif
kubectl get pods -n ingress-nginx
```

### Étape 2 : Vérifier que l'Ingress est configuré

```powershell
# Vérifier que l'Ingress existe
kubectl get ingress smarthome-ingress -n smarthome

# Voir les détails
kubectl describe ingress smarthome-ingress -n smarthome
```

### Étape 3 : Obtenir l'IP de l'Ingress

```powershell
# Obtenir l'IP de Minikube (si vous utilisez Minikube)
minikube ip

# Ou obtenir l'IP de l'Ingress directement
kubectl get ingress smarthome-ingress -n smarthome -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Vous obtiendrez une IP, par exemple : `192.168.49.2`

### Étape 4 : Configurer le fichier hosts (Windows)

1. **Ouvrez le fichier hosts en tant qu'administrateur** :
   ```
   C:\Windows\System32\drivers\etc\hosts
   ```

2. **Ajoutez cette ligne** (remplacez `<IP>` par l'IP obtenue à l'étape 3) :
   ```
   <IP> smarthome.local
   ```

   Exemple :
   ```
   192.168.49.2 smarthome.local
   ```

3. **Sauvegardez le fichier**

### Étape 5 : Accéder au frontend

Ouvrez votre navigateur et allez sur :
```
http://smarthome.local/
```

**✅ Avantages :**
- ✅ Accès permanent (pas besoin de garder un terminal ouvert)
- ✅ Configuration production-like
- ✅ Tous les services accessibles via le même domaine
- ✅ URL propre et mémorisable

**⚠️ Inconvénients :**
- ❌ Nécessite de modifier le fichier hosts
- ❌ Nécessite que l'Ingress Controller soit activé
- ❌ L'IP peut changer si le cluster est recréé

**📝 Configuration de l'Ingress :**

L'Ingress est défini dans `k8s/ingress/ingress.yaml` :
- **Host** : `smarthome.local`
- **Path du frontend** : `/` (racine, en dernier dans la liste)
- **Service** : `frontend-service`
- **Port** : `3000`

---

## 🎮 Méthode 4 : Via Minikube Service (Minikube uniquement)

**Si vous utilisez Minikube, cette méthode est très simple.**

```powershell
minikube service frontend-service -n smarthome
```

Cette commande va :
1. Ouvrir automatiquement votre navigateur
2. Créer un tunnel vers le service
3. Afficher l'URL d'accès

**✅ Avantages :**
- ✅ Très simple
- ✅ Ouvre automatiquement le navigateur
- ✅ Gère le tunnel automatiquement

**⚠️ Inconvénients :**
- ❌ Fonctionne uniquement avec Minikube
- ❌ Nécessite que Minikube soit en cours d'exécution

---

## 🔧 Méthode 5 : Via LoadBalancer (Si Disponible)

**Si votre cluster Kubernetes supporte LoadBalancer (cloud providers).**

### Étape 1 : Créer un service LoadBalancer

Créez un fichier `k8s/services/frontend/service-loadbalancer.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service-loadbalancer
  namespace: smarthome
  labels:
    app: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: frontend
```

### Étape 2 : Appliquer le service

```powershell
kubectl apply -f k8s/services/frontend/service-loadbalancer.yaml
```

### Étape 3 : Obtenir l'IP externe

```powershell
kubectl get service frontend-service-loadbalancer -n smarthome
```

Attendez que la colonne `EXTERNAL-IP` affiche une IP (peut prendre quelques minutes).

### Étape 4 : Accéder au frontend

Ouvrez votre navigateur et allez sur :
```
http://<EXTERNAL-IP>
```

**✅ Avantages :**
- ✅ IP externe publique
- ✅ Accessible depuis Internet (si configuré)
- ✅ Pas besoin de configuration locale

**⚠️ Inconvénients :**
- ❌ Nécessite un cluster avec support LoadBalancer
- ❌ Peut prendre du temps pour obtenir une IP
- ❌ Peut avoir un coût (cloud providers)

---

## 📊 Comparaison des Méthodes

| Méthode | Simplicité | Permanence | Production | URL | Recommandation |
|---------|-----------|------------|------------|-----|----------------|
| **Port-Forward** | ⭐⭐⭐⭐⭐ | ❌ | ❌ | `http://localhost:3000` | Développement/Test |
| **NodePort** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | `http://<IP>:30000` | Développement/Test |
| **Ingress** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | `http://smarthome.local/` | Production |
| **Minikube Service** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ | Auto-ouvert | Minikube uniquement |
| **LoadBalancer** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | `http://<EXTERNAL-IP>` | Cloud/Production |

---

## ✅ Recommandations par Cas d'Usage

### Pour Tester Rapidement
👉 **Utilisez la Méthode 1 (Port-Forward)**
```powershell
kubectl port-forward service/frontend-service 3000:3000 -n smarthome
```
Puis ouvrez : `http://localhost:3000`

### Pour un Accès Permanent (Développement)
👉 **Utilisez la Méthode 2 (NodePort)**
```powershell
kubectl apply -f k8s/services/frontend/service-nodeport.yaml
minikube ip  # Obtenir l'IP
```
Puis ouvrez : `http://<IP>:30000`

### Pour un Environnement de Production
👉 **Utilisez la Méthode 3 (Ingress)**
1. Activez l'Ingress Controller
2. Configurez le fichier hosts
3. Accédez à : `http://smarthome.local/`

### Si Vous Utilisez Minikube
👉 **Utilisez la Méthode 4 (Minikube Service)**
```powershell
minikube service frontend-service -n smarthome
```

---

## 🔍 Vérification et Dépannage

### Vérifier que le Frontend Fonctionne

```powershell
# Vérifier que les pods sont prêts
kubectl get pods -n smarthome -l app=frontend

# Vérifier les logs
kubectl logs -f deployment/frontend -n smarthome

# Vérifier les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-String -Pattern "frontend"
```

### Le Port-Forward ne Fonctionne pas

```powershell
# Vérifier que le service existe
kubectl get service frontend-service -n smarthome

# Vérifier que les pods sont prêts
kubectl get pods -n smarthome -l app=frontend

# Vérifier les logs du frontend
kubectl logs -f deployment/frontend -n smarthome
```

### L'Ingress ne Fonctionne pas

```powershell
# Vérifier que l'Ingress Controller est actif
kubectl get pods -n ingress-nginx

# Vérifier la configuration de l'Ingress
kubectl describe ingress smarthome-ingress -n smarthome

# Vérifier les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp'
```

### Le Frontend ne Peut pas se Connecter au Backend

Le frontend utilise des variables d'environnement pour se connecter aux services backend. Vérifiez :

```powershell
# Vérifier les variables d'environnement
kubectl get deployment frontend -n smarthome -o yaml | Select-String -Pattern "NEXT_PUBLIC\|BASE_URL"

# Vérifier que les services backend sont accessibles
kubectl get services -n smarthome | Select-String -Pattern "usage-collector\|device-simulator\|peak-detector\|optimizer\|billing"
```

**Variables d'environnement configurées dans le deployment :**
- `NEXT_PUBLIC_BACKEND_URL`: `http://usage-collector-service:8083`
- `USAGE_BASE_URL`: `http://usage-collector-service:8083`
- `DEVICE_BASE_URL`: `http://device-simulator-service:8082`
- `PEAK_BASE_URL`: `http://peak-detector-service:8084`
- `OPTIMIZER_BASE_URL`: `http://optimizer-service:8085`
- `BILLING_BASE_URL`: `http://billing-service:8086`

---

## 📝 Fichiers de Configuration

### Service ClusterIP (Par Défaut)
- **Fichier** : `k8s/services/frontend/service.yaml`
- **Type** : `ClusterIP`
- **Port** : `3000`

### Service NodePort
- **Fichier** : `k8s/services/frontend/service-nodeport.yaml`
- **Type** : `NodePort`
- **Port du service** : `3000`
- **NodePort** : `30000`

### Deployment
- **Fichier** : `k8s/services/frontend/deployment.yaml`
- **Image** : `salmaidoufkir/frontend:latest`
- **Réplicas** : `1`
- **Port du conteneur** : `3000`

### Ingress
- **Fichier** : `k8s/ingress/ingress.yaml`
- **Host** : `smarthome.local`
- **Path** : `/` (racine)
- **Service** : `frontend-service`
- **Port** : `3000`

---

## 🎯 Prochaines Étapes

Une fois que vous pouvez accéder au frontend :

1. **Vérifier que le frontend charge** : Vous devriez voir l'interface "Smart Home Energy Monitor"
2. **Vérifier la connexion au backend** : Le frontend devrait afficher les données de consommation en temps réel
3. **Vérifier les logs** : Si quelque chose ne fonctionne pas, consultez les logs avec `kubectl logs -f deployment/frontend -n smarthome`

---

## 🔗 Ressources Complémentaires

- **Guide d'accès au frontend** : `GUIDE-ACCES-FRONTEND-KUBERNETES.md`
- **Guide de déploiement** : `GUIDE-DEPLOIEMENT-FRONTEND-KUBERNETES.md`
- **Solution d'accès par IP** : `SOLUTION-ACCES-FRONTEND-IP.md`
- **Guide NodePort Backend** : `GUIDE-FRONTEND-NODEPORT-BACKEND.md`

---

**Bon accès au frontend ! 🚀**

