# Guide : Tester les Services avec Postman

Ce guide explique comment tester tous vos microservices déployés sur Kubernetes avec Postman.

---

## 📋 Prérequis

- Postman installé
- Cluster Kubernetes en cours d'exécution
- Tous les services déployés dans le namespace `smarthome`

---

## 🔌 Étape 1 : Exposer les Services via Port-Forward

Les services Kubernetes ne sont pas accessibles directement depuis votre machine. Vous devez utiliser `port-forward` pour les exposer localement.

### Option A : Port-Forward Manuel (Terminal séparé pour chaque service)

Ouvrez **4 terminaux PowerShell** et exécutez dans chacun :

**Terminal 1 - Usage Collector Service (port 8083) :**
```powershell
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome
```

**Terminal 2 - Peak Detector Service (port 8084) :**
```powershell
kubectl port-forward service/peak-detector-service 8084:8084 -n smarthome
```

**Terminal 3 - Optimizer Service (port 8085) :**
```powershell
kubectl port-forward service/optimizer-service 8085:8085 -n smarthome
```

**Terminal 4 - Device Simulator Service (port 8082) :**
```powershell
kubectl port-forward service/device-simulator-service 8082:8082 -n smarthome
```

### Option B : Script PowerShell (Tous les services en arrière-plan)

Créez un fichier `start-port-forwards.ps1` :

```powershell
# Démarrer tous les port-forwards en arrière-plan
Write-Host "Démarrage des port-forwards..." -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/peak-detector-service 8084:8084 -n smarthome"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/optimizer-service 8085:8085 -n smarthome"
Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/device-simulator-service 8082:8082 -n smarthome"

Write-Host "✅ Tous les port-forwards sont démarrés" -ForegroundColor Green
Write-Host "Les services sont maintenant accessibles sur localhost" -ForegroundColor Cyan
```

---

## 🧪 Étape 2 : Tests avec Postman

### 1. Usage Collector Service (Port 8083)

#### Health Check
```
GET http://localhost:8083/actuator/health
```

**Réponse attendue :**
```json
{
  "status": "UP",
  "groups": ["liveness", "readiness"]
}
```

#### Consommation Actuelle
```
GET http://localhost:8083/usage/current
```

**Réponse attendue :**
```json
{
  "totalPowerKw": 2.5,
  "deviceCount": 5,
  "devices": {
    "device1": 0.5,
    "device2": 0.8,
    ...
  }
}
```

#### Historique de Consommation
```
GET http://localhost:8083/usage/history?limit=10
```

**Paramètres :**
- `limit` (optionnel, défaut: 100) : Nombre d'entrées à retourner

**Réponse attendue :**
```json
[
  {
    "id": 1,
    "timestamp": "2025-12-06T15:30:00Z",
    "totalPowerKw": 2.5,
    "deviceCount": 5
  },
  ...
]
```

#### État des Appareils
```
GET http://localhost:8083/usage/devices
```

**Réponse attendue :**
```json
{
  "device1": 0.5,
  "device2": 0.8,
  "device3": 0.3,
  ...
}
```

#### Sauvegarder un Snapshot
```
POST http://localhost:8083/usage/save
```

**Réponse attendue :**
```json
{
  "message": "Snapshot sauvegardé avec succès",
  "totalPowerKw": 2.5
}
```

---

### 2. Peak Detector Service (Port 8084)

#### Health Check
```
GET http://localhost:8084/actuator/health
```

**Réponse attendue :**
```json
{
  "status": "UP"
}
```

---

### 3. Optimizer Service (Port 8085)

#### Health Check
```
GET http://localhost:8085/optimizer/health
```

**Réponse attendue :**
```json
{
  "status": "UP",
  "service": "optimizer-service",
  "message": "Service opérationnel et prêt à recevoir les alertes"
}
```

#### Informations du Service
```
GET http://localhost:8085/optimizer/info
```

**Réponse attendue :**
```json
{
  "service": "optimizer-service",
  "description": "Service d'optimisation de la consommation énergétique",
  "functionality": "Écoute les alertes de pic et envoie des commandes aux appareils",
  "listeningQueue": "peak.alerts.queue",
  "sendingExchange": "control.commands.exchange"
}
```

---

### 4. Device Simulator Service (Port 8082)

#### Health Check
```
GET http://localhost:8082/actuator/health
```

**Réponse attendue :**
```json
{
  "status": "UP"
}
```

#### Liste des Appareils Simulés
```
GET http://localhost:8082/devices
```

**Réponse attendue :**
```json
[
  {
    "id": "device1",
    "name": "Lave-linge",
    "powerKw": 0.5,
    "status": "ON"
  },
  {
    "id": "device2",
    "name": "Lave-vaisselle",
    "powerKw": 0.8,
    "status": "ON"
  },
  ...
]
```

---

## 📦 Collection Postman

### Créer une Collection Postman

1. **Ouvrez Postman**
2. **Créez une nouvelle Collection** : "Smart Home Load Balancer"
3. **Ajoutez les requêtes suivantes** :

#### Variables de Collection

Créez des variables dans votre collection :
- `base_url_usage` : `http://localhost:8083`
- `base_url_peak` : `http://localhost:8084`
- `base_url_optimizer` : `http://localhost:8085`
- `base_url_device` : `http://localhost:8082`

#### Requêtes à Ajouter

**Usage Collector Service :**
1. `GET {{base_url_usage}}/actuator/health`
2. `GET {{base_url_usage}}/usage/current`
3. `GET {{base_url_usage}}/usage/history?limit=10`
4. `GET {{base_url_usage}}/usage/devices`
5. `POST {{base_url_usage}}/usage/save`

**Peak Detector Service :**
1. `GET {{base_url_peak}}/actuator/health`

**Optimizer Service :**
1. `GET {{base_url_optimizer}}/optimizer/health`
2. `GET {{base_url_optimizer}}/optimizer/info`

**Device Simulator Service :**
1. `GET {{base_url_device}}/actuator/health`
2. `GET {{base_url_device}}/devices`

---

## 🧪 Scénario de Test Complet

### Test 1 : Vérifier que tous les services sont UP

1. Tester tous les health checks
2. Tous doivent retourner `"status": "UP"`

### Test 2 : Flux de Données

1. **GET /devices** (Device Simulator) → Voir les appareils
2. **GET /usage/current** (Usage Collector) → Voir la consommation actuelle
3. **POST /usage/save** (Usage Collector) → Sauvegarder un snapshot
4. **GET /usage/history** (Usage Collector) → Vérifier que le snapshot est sauvegardé

### Test 3 : Communication entre Services

1. Les services communiquent via RabbitMQ (pas directement via HTTP)
2. Vérifier dans RabbitMQ Management que les messages sont échangés

---

## 🔍 Vérification RabbitMQ (Bonus)

Pour voir les messages échangés entre services :

```powershell
# Port-forward RabbitMQ Management
kubectl port-forward service/rabbitmq-service 15672:15672 -n smarthome
```

Puis ouvrez dans le navigateur :
- **URL** : http://localhost:15672
- **Username** : `guest`
- **Password** : `guest`

Dans l'interface RabbitMQ, vous pouvez voir :
- Les queues créées
- Les messages échangés
- Les exchanges

---

## 🐛 Dépannage

### Erreur : "Connection refused"

**Cause :** Le port-forward n'est pas actif.

**Solution :**
```powershell
# Vérifier que le port-forward est actif
kubectl get pods -n smarthome

# Relancer le port-forward
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome
```

### Erreur : "Address already in use"

**Cause :** Le port est déjà utilisé.

**Solution :**
```powershell
# Utiliser un autre port
kubectl port-forward service/usage-collector-service 18083:8083 -n smarthome
# Puis dans Postman, utilisez http://localhost:18083
```

### Le service ne répond pas

**Vérifications :**
1. Le pod est-il Running ?
   ```powershell
   kubectl get pods -n smarthome
   ```

2. Le service existe-t-il ?
   ```powershell
   kubectl get services -n smarthome
   ```

3. Voir les logs du pod
   ```powershell
   kubectl logs -f deployment/usage-collector-service -n smarthome
   ```

---

## ✅ Checklist de Test

- [ ] Tous les port-forwards sont actifs
- [ ] Health checks retournent `"status": "UP"`
- [ ] `/usage/current` retourne des données
- [ ] `/usage/history` retourne l'historique
- [ ] `/devices` retourne la liste des appareils
- [ ] `/usage/save` sauvegarde un snapshot
- [ ] Les services communiquent via RabbitMQ

---

## 📝 Exemple de Collection Postman JSON

Vous pouvez importer cette collection dans Postman :

```json
{
  "info": {
    "name": "Smart Home Load Balancer",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url_usage",
      "value": "http://localhost:8083"
    },
    {
      "key": "base_url_peak",
      "value": "http://localhost:8084"
    },
    {
      "key": "base_url_optimizer",
      "value": "http://localhost:8085"
    },
    {
      "key": "base_url_device",
      "value": "http://localhost:8082"
    }
  ],
  "item": [
    {
      "name": "Usage Collector",
      "item": [
        {
          "name": "Health Check",
          "request": {
            "method": "GET",
            "url": "{{base_url_usage}}/actuator/health"
          }
        },
        {
          "name": "Current Usage",
          "request": {
            "method": "GET",
            "url": "{{base_url_usage}}/usage/current"
          }
        },
        {
          "name": "Usage History",
          "request": {
            "method": "GET",
            "url": "{{base_url_usage}}/usage/history?limit=10"
          }
        },
        {
          "name": "Devices",
          "request": {
            "method": "GET",
            "url": "{{base_url_usage}}/usage/devices"
          }
        },
        {
          "name": "Save Snapshot",
          "request": {
            "method": "POST",
            "url": "{{base_url_usage}}/usage/save"
          }
        }
      ]
    },
    {
      "name": "Optimizer",
      "item": [
        {
          "name": "Health",
          "request": {
            "method": "GET",
            "url": "{{base_url_optimizer}}/optimizer/health"
          }
        },
        {
          "name": "Info",
          "request": {
            "method": "GET",
            "url": "{{base_url_optimizer}}/optimizer/info"
          }
        }
      ]
    },
    {
      "name": "Device Simulator",
      "item": [
        {
          "name": "Health Check",
          "request": {
            "method": "GET",
            "url": "{{base_url_device}}/actuator/health"
          }
        },
        {
          "name": "Get Devices",
          "request": {
            "method": "GET",
            "url": "{{base_url_device}}/devices"
          }
        }
      ]
    }
  ]
}
```

---

**Note :** Gardez les terminaux avec les port-forwards ouverts pendant vos tests. Si vous fermez un terminal, le port-forward s'arrête et vous devrez le relancer.

