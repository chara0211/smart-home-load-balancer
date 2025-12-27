# Guide : Accès Automatique à Tous les Services

Ce guide explique comment accéder à tous vos services sans avoir à exécuter `minikube service` pour chacun individuellement.

## 🚀 Solution 1 : Script Port-Forward (Recommandé)

Ce script lance automatiquement tous les port-forwards en arrière-plan, permettant d'accéder à tous les services via `localhost`.

### Utilisation

```powershell
.\scripts\start-all-services-port-forward.ps1
```

### Ce que fait le script

1. Vérifie que kubectl et le namespace existent
2. Lance un port-forward pour chaque service dans une fenêtre PowerShell séparée
3. Affiche les URLs d'accès pour chaque service

### URLs d'accès

Une fois le script exécuté, tous les services sont accessibles via :

- **Frontend** : http://localhost:3000
- **Usage Collector Service** : http://localhost:8083
- **Device Simulator Service** : http://localhost:8082
- **Peak Detector Service** : http://localhost:8084
- **Optimizer Service** : http://localhost:8085
- **Billing Service** : http://localhost:8086

### Arrêter les port-forwards

Fermez simplement les fenêtres PowerShell qui ont été ouvertes par le script.

---

## 🎯 Solution 2 : Script Minikube Service

Ce script ouvre automatiquement tous les services avec `minikube service` dans le navigateur.

### Utilisation

```powershell
.\scripts\start-all-services-minikube-service.ps1
```

### Ce que fait le script

1. Vérifie que Minikube est en cours d'exécution
2. Lance `minikube service` pour chaque service NodePort
3. Ouvre automatiquement votre navigateur pour chaque service

### Avantages

- ✅ Ouvre automatiquement le navigateur
- ✅ Utilise les services NodePort déjà configurés
- ✅ Pas besoin de garder des terminaux ouverts

---

## 📋 Comparaison des Solutions

| Solution | Avantages | Inconvénients |
|----------|-----------|---------------|
| **Port-Forward** | ✅ Accès via localhost<br>✅ Plus simple<br>✅ Fonctionne toujours | ❌ Plusieurs fenêtres PowerShell |
| **Minikube Service** | ✅ Ouvre le navigateur automatiquement<br>✅ Utilise NodePort | ❌ Plusieurs fenêtres PowerShell<br>❌ Nécessite NodePort |

---

## 🔧 Solution Alternative : Port-Forward Manuel

Si vous préférez lancer les port-forwards manuellement, voici les commandes :

```powershell
# Frontend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/frontend-service 3000:3000 -n smarthome"

# Usage Collector
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome"

# Device Simulator
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/device-simulator-service 8082:8082 -n smarthome"

# Peak Detector
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/peak-detector-service 8084:8084 -n smarthome"

# Optimizer
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/optimizer-service 8085:8085 -n smarthome"

# Billing
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/billing-service 8086:8086 -n smarthome"
```

---

## 🎯 Recommandation

**Utilisez la Solution 1 (Script Port-Forward)** car :
- ✅ Fonctionne de manière fiable
- ✅ Accès simple via localhost
- ✅ Pas de dépendance à Minikube tunnel
- ✅ Facile à arrêter (fermer les fenêtres)

---

## 📝 Scripts Disponibles

- `scripts/start-all-services-port-forward.ps1` - Lance tous les port-forwards
- `scripts/start-all-services-minikube-service.ps1` - Ouvre tous les services avec minikube service

---

## 🐛 Dépannage

### Les port-forwards ne démarrent pas

1. Vérifiez que kubectl fonctionne : `kubectl version --client`
2. Vérifiez que le namespace existe : `kubectl get namespace smarthome`
3. Vérifiez que les services existent : `kubectl get services -n smarthome`

### Les ports sont déjà utilisés

Si un port est déjà utilisé, vous verrez une erreur. Arrêtez le processus qui utilise le port ou modifiez le port dans le script.

### Les services ne répondent pas

1. Vérifiez que les pods sont en cours d'exécution : `kubectl get pods -n smarthome`
2. Vérifiez les logs : `kubectl logs -f deployment/<service-name> -n smarthome`

---

**Avec ces scripts, vous pouvez accéder à tous vos services en une seule commande ! 🎉**

