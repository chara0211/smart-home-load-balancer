# Guide : Frontend utilisant les Backends via NodePort

## ✅ Configuration Actuelle

Le frontend est maintenant configuré pour utiliser les services backend via leurs **NodePorts** au lieu des noms de services internes.

## 🔧 Configuration

### Services NodePort Backend Disponibles

| Service | NodePort | URL Complète |
|---------|----------|--------------|
| **usage-collector-service** | 30083 | `http://172.30.95.94:30083` |
| **peak-detector-service** | 30084 | `http://172.30.95.94:30084` |
| **device-simulator-service** | 30082 | `http://172.30.95.94:30082` |
| **optimizer-service** | 30085 | `http://172.30.95.94:30085` |

### Configuration du Frontend

Le frontend utilise la variable d'environnement `NEXT_PUBLIC_BACKEND_URL` configurée dans le deployment :

```yaml
env:
- name: NEXT_PUBLIC_BACKEND_URL
  value: "http://172.30.95.94:30083"
```

Cette URL est utilisée par le proxy Next.js configuré dans `next.config.js` pour rediriger les requêtes `/api/*` vers le backend.

## 📋 Fichiers Modifiés

### 1. `k8s/services/frontend/deployment.yaml`

Le deployment utilise maintenant l'IP du node avec le port NodePort :

```yaml
env:
- name: NEXT_PUBLIC_BACKEND_URL
  value: "http://172.30.95.94:30083"
```

### 2. `frontend/next.config.js`

Le proxy Next.js utilise la variable d'environnement :

```javascript
const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://usage-collector-service:8083';
```

## 🚀 Déploiement

Pour appliquer les changements :

```powershell
# Appliquer le deployment mis à jour
kubectl apply -f k8s/services/frontend/deployment.yaml

# Redémarrer le deployment pour prendre en compte les nouvelles variables
kubectl rollout restart deployment/frontend -n smarthome

# Vérifier que le pod redémarre
kubectl get pods -n smarthome -l app=frontend -w
```

## 🔍 Vérification

### 1. Vérifier que les services NodePort sont actifs

```powershell
kubectl get services -n smarthome | Select-String -Pattern "nodeport"
```

Vous devriez voir tous les services NodePort listés.

### 2. Vérifier la configuration du frontend

```powershell
# Vérifier les variables d'environnement du pod
kubectl exec -it deployment/frontend -n smarthome -- env | Select-String -Pattern "NEXT_PUBLIC"
```

### 3. Tester la connexion depuis le pod frontend

```powershell
# Tester la connexion au backend depuis le pod
kubectl exec -it deployment/frontend -n smarthome -- wget -O- http://172.30.95.94:30083/usage/current
```

### 4. Vérifier les logs du frontend

```powershell
kubectl logs -f deployment/frontend -n smarthome
```

## ⚠️ Notes Importantes

### Accès depuis un Pod

Depuis l'intérieur d'un pod Kubernetes, accéder à l'IP du node (`172.30.95.94`) peut ne pas fonctionner selon la configuration réseau de votre cluster. Si cela ne fonctionne pas, vous avez deux options :

#### Option A : Utiliser les services NodePort via leur nom

Modifiez le deployment pour utiliser le nom du service NodePort :

```yaml
env:
- name: NEXT_PUBLIC_BACKEND_URL
  value: "http://usage-collector-service-nodeport:8083"
```

**Note :** Cela utilisera le ClusterIP du service NodePort, pas vraiment le NodePort externe, mais cela fonctionnera depuis l'intérieur du cluster.

#### Option B : Utiliser l'IP du node (actuelle)

Si l'IP du node n'est pas accessible depuis les pods, vous devrez peut-être :
- Vérifier la configuration réseau de votre cluster
- Utiliser une autre méthode (Option A)

### Changer l'IP du Node

Si l'IP du node change, vous devrez mettre à jour le deployment :

```powershell
# Obtenir la nouvelle IP du node
kubectl get nodes -o wide

# Mettre à jour le deployment
kubectl set env deployment/frontend NEXT_PUBLIC_BACKEND_URL=http://<NOUVELLE_IP>:30083 -n smarthome
```

## 🔄 Alternative : Utiliser plusieurs Backends

Si vous voulez que le frontend utilise plusieurs services backend, vous pouvez ajouter plusieurs variables d'environnement :

```yaml
env:
- name: NEXT_PUBLIC_USAGE_COLLECTOR_URL
  value: "http://172.30.95.94:30083"
- name: NEXT_PUBLIC_PEAK_DETECTOR_URL
  value: "http://172.30.95.94:30084"
- name: NEXT_PUBLIC_DEVICE_SIMULATOR_URL
  value: "http://172.30.95.94:30082"
- name: NEXT_PUBLIC_OPTIMIZER_URL
  value: "http://172.30.95.94:30085"
```

Puis modifiez `next.config.js` pour utiliser ces différentes URLs selon le chemin.

## 📊 Avantages de cette Configuration

✅ **Accès direct aux services** : Le frontend accède directement aux services backend via leurs NodePorts  
✅ **Pas de dépendance aux noms de services internes** : Utilise les ports externes  
✅ **Compatible avec l'accès depuis l'extérieur** : Les mêmes URLs fonctionnent depuis le navigateur et depuis les pods  

## 🐛 Dépannage

### Le frontend ne peut pas se connecter au backend

1. **Vérifier que les services NodePort sont actifs** :
   ```powershell
   kubectl get services -n smarthome -l app=usage-collector-service
   ```

2. **Tester la connexion depuis votre machine** :
   ```powershell
   curl http://172.30.95.94:30083/usage/current
   ```

3. **Vérifier les logs du frontend** :
   ```powershell
   kubectl logs -f deployment/frontend -n smarthome
   ```

4. **Vérifier que l'IP du node est correcte** :
   ```powershell
   kubectl get nodes -o wide
   ```

### Erreur "Connection refused"

Si vous obtenez une erreur de connexion, essayez l'Option A (utiliser le nom du service NodePort) au lieu de l'IP du node.

---

**Configuration terminée ! Le frontend utilise maintenant les services backend via leurs NodePorts.** 🎉

