# Guide : Accès à Tous les Services via NodePort

Ce guide récapitule comment accéder à tous vos services déployés sur Kubernetes via NodePort, sans avoir besoin d'exécuter `minikube service` à chaque fois.

## 🌐 IP de Minikube

L'IP de votre cluster Minikube est : **192.168.49.2**

## 📋 Services Disponibles

Tous les services sont accessibles via l'IP de Minikube avec les ports NodePort suivants :

| Service | Port Interne | NodePort | URL d'Accès |
|---------|--------------|----------|-------------|
| **Frontend** | 3000 | 30000 | `http://192.168.49.2:30000` |
| **Usage Collector Service** | 8083 | 30083 | `http://192.168.49.2:30083` |
| **Device Simulator Service** | 8082 | 30082 | `http://192.168.49.2:30082` |
| **Peak Detector Service** | 8084 | 30084 | `http://192.168.49.2:30084` |
| **Optimizer Service** | 8085 | 30085 | `http://192.168.49.2:30085` |
| **Billing Service** | 8086 | 30086 | `http://192.168.49.2:30086` |

## ⚠️ Important : Minikube avec Docker Driver

Avec Minikube utilisant le driver Docker, l'accès direct via l'IP peut ne pas fonctionner. Vous avez **deux options** :

### Option 1 : Utiliser `minikube tunnel` (Recommandé pour un accès permanent)

Dans un terminal PowerShell **séparé** (en tant qu'administrateur), exécutez :

```powershell
minikube tunnel
```

**Gardez ce terminal ouvert.** Ensuite, vous pourrez accéder à tous les services directement via les URLs ci-dessus.

**Avantages :**
- ✅ Accès permanent à tous les services
- ✅ Pas besoin de garder plusieurs terminaux ouverts
- ✅ Fonctionne pour tous les services en même temps

**Inconvénients :**
- ❌ Nécessite un terminal ouvert en arrière-plan
- ❌ Nécessite les droits administrateur

### Option 2 : Utiliser Port-Forward (Alternative)

Si `minikube tunnel` ne fonctionne pas, vous pouvez utiliser `kubectl port-forward` pour chaque service :

```powershell
# Frontend
kubectl port-forward service/frontend-service 3000:3000 -n smarthome

# Usage Collector
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome

# Device Simulator
kubectl port-forward service/device-simulator-service 8082:8082 -n smarthome

# Peak Detector
kubectl port-forward service/peak-detector-service 8084:8084 -n smarthome

# Optimizer
kubectl port-forward service/optimizer-service 8085:8085 -n smarthome

# Billing
kubectl port-forward service/billing-service 8086:8086 -n smarthome
```

Puis accédez via `http://localhost:<port>`.

## 🚀 Démarrage Rapide

### Étape 1 : Démarrer le tunnel Minikube

Ouvrez un **nouveau terminal PowerShell en tant qu'administrateur** et exécutez :

```powershell
minikube tunnel
```

**Gardez ce terminal ouvert.**

### Étape 2 : Accéder aux services

Ouvrez votre navigateur et accédez aux services :

- **Frontend** : http://192.168.49.2:30000
- **Usage Collector API** : http://192.168.49.2:30083
- **Device Simulator API** : http://192.168.49.2:30082
- **Peak Detector API** : http://192.168.49.2:30084
- **Optimizer API** : http://192.168.49.2:30085
- **Billing API** : http://192.168.49.2:30086

## 🔍 Vérification

Pour vérifier que tous les services NodePort sont bien déployés :

```powershell
kubectl get services -n smarthome | Select-String -Pattern "nodeport"
```

Vous devriez voir :
- `frontend-service-nodeport`
- `usage-collector-service-nodeport`
- `device-simulator-service-nodeport`
- `peak-detector-service-nodeport`
- `optimizer-service-nodeport`
- `billing-service-nodeport`

## 📝 Endpoints des Services

### Frontend
- **URL** : http://192.168.49.2:30000
- **Description** : Interface utilisateur Next.js

### Usage Collector Service
- **URL** : http://192.168.49.2:30083
- **Endpoints** :
  - `GET /usage/current` - Consommation actuelle
  - `GET /usage/history` - Historique
  - `GET /actuator/health` - Health check

### Device Simulator Service
- **URL** : http://192.168.49.2:30082
- **Endpoints** :
  - `GET /devices` - Liste des appareils
  - `POST /devices/simulate` - Simuler des appareils
  - `GET /actuator/health` - Health check

### Peak Detector Service
- **URL** : http://192.168.49.2:30084
- **Endpoints** :
  - `GET /peaks` - Détecter les pics
  - `GET /actuator/health` - Health check

### Optimizer Service
- **URL** : http://192.168.49.2:30085
- **Endpoints** :
  - `GET /optimize` - Optimiser la consommation
  - `GET /actuator/health` - Health check

### Billing Service
- **URL** : http://192.168.49.2:30086
- **Endpoints** :
  - `GET /billing` - Facturation
  - `GET /actuator/health` - Health check

## 🐛 Dépannage

### Le tunnel ne fonctionne pas

1. **Vérifier que vous êtes administrateur** : Le tunnel nécessite les droits administrateur
2. **Vérifier que Minikube est en cours d'exécution** : `minikube status`
3. **Redémarrer le tunnel** : Arrêtez (`Ctrl+C`) et relancez `minikube tunnel`

### Les services ne sont pas accessibles

1. **Vérifier que les services NodePort existent** :
   ```powershell
   kubectl get services -n smarthome | Select-String -Pattern "nodeport"
   ```

2. **Vérifier que les pods sont en cours d'exécution** :
   ```powershell
   kubectl get pods -n smarthome
   ```

3. **Vérifier les logs d'un service** :
   ```powershell
   kubectl logs -f deployment/<service-name> -n smarthome
   ```

### L'IP de Minikube a changé

Si l'IP de Minikube change (après un redémarrage), obtenez la nouvelle IP :

```powershell
minikube ip
```

Puis utilisez cette nouvelle IP dans les URLs.

## 📝 Fichiers de Configuration

Tous les services NodePort sont configurés dans :
- `k8s/services/frontend/service-nodeport.yaml`
- `k8s/services/usage-collector/service-nodeport.yaml`
- `k8s/services/device-simulator/service-nodeport.yaml`
- `k8s/services/peak-detector/service-nodeport.yaml`
- `k8s/services/optimizer/service-nodeport.yaml`
- `k8s/services/billing/service-nodeport.yaml`

## ✅ Résumé

Pour accéder à tous vos services :

1. **Démarrer le tunnel** : `minikube tunnel` (dans un terminal admin)
2. **Accéder aux services** via les URLs avec l'IP de Minikube (192.168.49.2) et les ports NodePort

**Tous les services sont maintenant accessibles sans avoir à exécuter `minikube service` pour chacun !** 🎉

