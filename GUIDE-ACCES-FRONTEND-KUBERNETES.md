# Guide : Accéder au Frontend sur Kubernetes

Ce guide explique toutes les méthodes pour accéder à votre frontend déployé sur Kubernetes.

## 🔍 Vérification Préalable

Avant d'accéder au frontend, vérifiez qu'il est bien déployé :

```powershell
# Vérifier que les pods sont en cours d'exécution
kubectl get pods -n smarthome -l app=frontend

# Vérifier que le service existe
kubectl get service frontend-service -n smarthome
```

Vous devriez voir 2 pods en état `Running` et un service de type `ClusterIP`.

---

## 🚀 Méthode 1 : Port-Forward (Rapide pour Tester)

**La méthode la plus simple et rapide pour tester localement.**

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

**⚠️ Inconvénients :**
- ❌ Le port-forward doit rester actif (terminal ouvert)
- ❌ Arrête si vous fermez le terminal

---

## 🌐 Méthode 2 : Via Ingress (Production-like)

**Méthode recommandée pour un accès permanent.**

### Étape 1 : Vérifier que l'Ingress Controller est activé

```powershell
# Si vous utilisez Minikube
minikube addons enable ingress

# Vérifier que l'Ingress est actif
kubectl get ingress -n smarthome
```

### Étape 2 : Obtenir l'IP de l'Ingress

```powershell
# Obtenir l'IP de Minikube (si vous utilisez Minikube)
minikube ip

# Ou obtenir l'IP de l'Ingress directement
kubectl get ingress smarthome-ingress -n smarthome
```

Vous obtiendrez une IP, par exemple : `192.168.49.2`

### Étape 3 : Configurer le fichier hosts (Windows)

1. Ouvrez le fichier hosts en tant qu'administrateur :
   ```
   C:\Windows\System32\drivers\etc\hosts
   ```

2. Ajoutez cette ligne (remplacez `<IP>` par l'IP obtenue à l'étape 2) :
   ```
   <IP> smarthome.local
   ```

   Exemple :
   ```
   192.168.49.2 smarthome.local
   ```

3. Sauvegardez le fichier

### Étape 4 : Accéder au frontend

Ouvrez votre navigateur et allez sur :
```
http://smarthome.local/
```

**✅ Avantages :**
- ✅ Accès permanent (pas besoin de garder un terminal ouvert)
- ✅ Configuration production-like
- ✅ Tous les services accessibles via le même domaine

**⚠️ Note :** Le frontend est configuré à la racine `/` dans l'Ingress, donc il sera accessible directement sur `http://smarthome.local/`

---

## 🔌 Méthode 3 : Via NodePort (Comme les autres services)

**Si vous avez déjà configuré NodePort pour les autres services, vous pouvez faire pareil pour le frontend.**

### Étape 1 : Créer un service NodePort pour le frontend

Créez un fichier `k8s/services/frontend/service-nodeport.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service-nodeport
  namespace: smarthome
  labels:
    app: frontend
spec:
  type: NodePort
  ports:
  - port: 3000
    targetPort: 3000
    nodePort: 30000
    protocol: TCP
    name: http
  selector:
    app: frontend
```

### Étape 2 : Appliquer le service NodePort

```powershell
kubectl apply -f k8s/services/frontend/service-nodeport.yaml
```

### Étape 3 : Obtenir l'IP du cluster

```powershell
# Si vous utilisez Minikube
minikube ip

# Sinon, obtenez l'IP d'un node
kubectl get nodes -o wide
```

### Étape 4 : Accéder au frontend

Ouvrez votre navigateur et allez sur :
```
http://<IP-DU-CLUSTER>:30000
```

Exemple : `http://192.168.49.2:30000`

**✅ Avantages :**
- ✅ Accès direct sans configuration supplémentaire
- ✅ Pas besoin de port-forward
- ✅ Permanent

---

## 🎯 Méthode 4 : Via Minikube Service (Minikube uniquement)

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

---

## 🔧 Dépannage

### Le port-forward ne fonctionne pas

```powershell
# Vérifier que le service existe
kubectl get service frontend-service -n smarthome

# Vérifier que les pods sont prêts
kubectl get pods -n smarthome -l app=frontend

# Vérifier les logs du frontend
kubectl logs -f deployment/frontend -n smarthome
```

### L'Ingress ne fonctionne pas

```powershell
# Vérifier que l'Ingress Controller est actif
kubectl get pods -n ingress-nginx

# Vérifier la configuration de l'Ingress
kubectl describe ingress smarthome-ingress -n smarthome

# Vérifier les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp'
```

### Le frontend ne peut pas se connecter au backend

Le frontend utilise la variable d'environnement `NEXT_PUBLIC_BACKEND_URL` pour se connecter au backend. Vérifiez :

```powershell
# Vérifier la variable d'environnement
kubectl get deployment frontend -n smarthome -o yaml | Select-String -Pattern "NEXT_PUBLIC_BACKEND_URL"

# Vérifier que le service backend est accessible
kubectl get service usage-collector-service -n smarthome
```

---

## 📊 Comparaison des Méthodes

| Méthode | Simplicité | Permanence | Production | Recommandation |
|---------|-----------|------------|------------|----------------|
| **Port-Forward** | ⭐⭐⭐⭐⭐ | ❌ | ❌ | Développement/Test |
| **Ingress** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Production |
| **NodePort** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Développement/Test |
| **Minikube Service** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ | Minikube uniquement |

---

## ✅ Recommandation

- **Pour tester rapidement** : Utilisez **Port-Forward** (Méthode 1)
- **Pour un accès permanent** : Utilisez **Ingress** (Méthode 2)
- **Si vous utilisez Minikube** : Utilisez **Minikube Service** (Méthode 4)

---

## 🎯 Prochaines Étapes

Une fois que vous pouvez accéder au frontend :

1. **Vérifier que le frontend charge** : Vous devriez voir l'interface "Smart Home Energy Monitor"
2. **Vérifier la connexion au backend** : Le frontend devrait afficher les données de consommation en temps réel
3. **Vérifier les logs** : Si quelque chose ne fonctionne pas, consultez les logs avec `kubectl logs -f deployment/frontend -n smarthome`

---

**Bon test ! 🚀**

