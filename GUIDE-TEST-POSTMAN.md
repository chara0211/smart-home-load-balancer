# Guide de Test avec Postman

Ce guide explique comment tester tous les services de Smart Home Load Balancer avec Postman via l'Ingress Kubernetes.

## 📋 Prérequis

1. **Postman** installé sur votre machine
2. **Kubernetes** avec Ingress configuré (voir `scripts/setup-ingress.ps1`)
3. Tous les services déployés dans le namespace `smarthome`

## 🔍 Étape 1 : Obtenir l'adresse de l'Ingress

### Option A : Via Minikube (recommandé)

```powershell
# Obtenir l'IP de Minikube
minikube ip

# Exemple de résultat : 192.168.49.2
```

### Option B : Via kubectl

```powershell
# Obtenir l'IP de l'Ingress
kubectl get ingress smarthome-ingress -n smarthome

# Ou directement l'IP
kubectl get ingress smarthome-ingress -n smarthome -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## ⚙️ Étape 2 : Configurer Postman

### Méthode 1 : Utiliser le fichier hosts (Recommandé)

1. **Ouvrir le fichier hosts en tant qu'administrateur** :
   - Chemin : `C:\Windows\System32\drivers\etc\hosts`
   - Clic droit → Ouvrir avec → Bloc-notes (en tant qu'administrateur)

2. **Ajouter cette ligne** (remplacez `192.168.49.2` par votre IP Minikube) :
   ```
   192.168.49.2 smarthome.local
   ```

3. **Sauvegarder** le fichier

4. **Dans Postman**, utilisez directement :
   - Base URL : `http://smarthome.local`

### Méthode 2 : Utiliser l'IP directement avec Header Host

Si vous ne voulez pas modifier le fichier hosts, vous pouvez :

1. **Dans Postman**, créez une variable d'environnement :
   - Variable : `base_url`
   - Valeur : `http://192.168.49.2` (remplacez par votre IP)

2. **Ajoutez un header** dans chaque requête :
   - Header : `Host`
   - Value : `smarthome.local`

## 📝 Étape 3 : Créer une Collection Postman

### Configuration de la Collection

1. Créez une nouvelle collection dans Postman
2. Ajoutez une variable de collection :
   - Variable : `base_url`
   - Valeur : `http://smarthome.local` (ou `http://192.168.49.2` si méthode 2)
   - Scope : Collection

## 🚀 Endpoints à Tester

### 1. Usage Collector Service

**Base Path** : `/usage`

#### GET - Consommation actuelle
```
GET {{base_url}}/usage/current
```

**Réponse attendue** :
```json
{
  "totalPowerKw": 2.5,
  "deviceCount": 5,
  "devices": {
    "device-1": 0.5,
    "device-2": 0.8,
    "device-3": 0.6,
    "device-4": 0.4,
    "device-5": 0.2
  }
}
```

#### GET - Historique de consommation
```
GET {{base_url}}/usage/history?limit=10
```

**Paramètres** :
- `limit` (optionnel, défaut: 100) : Nombre d'entrées à retourner

#### GET - État des appareils
```
GET {{base_url}}/usage/devices
```

**Réponse attendue** :
```json
{
  "device-1": 0.5,
  "device-2": 0.8,
  "device-3": 0.6
}
```

#### POST - Sauvegarder un snapshot
```
POST {{base_url}}/usage/save
```

**Headers** :
- `Content-Type: application/json` (optionnel, pas de body requis)

**Body** : 
- **Aucun body requis** - Cet endpoint ne prend pas de paramètres

**Réponse attendue** (200 OK) :
```json
{
  "message": "Snapshot sauvegardé avec succès",
  "totalPowerKw": 2.5
}
```

**Description** : 
Sauvegarde un snapshot de l'état actuel de la consommation énergétique dans la base de données PostgreSQL. L'endpoint récupère automatiquement les données actuelles depuis le service d'agrégation et les enregistre avec un timestamp.

---

### 2. Peak Detector Service

**Base Path** : `/peak`

#### GET - Health Check (via Actuator)
```
GET {{base_url}}/peak/actuator/health
```

#### GET - Info (via Actuator)
```
GET {{base_url}}/peak/actuator/info
```

**Note** : Le Peak Detector Service n'a pas de contrôleur REST exposé. Il fonctionne en arrière-plan et envoie des alertes via RabbitMQ.

---

### 3. Optimizer Service

**Base Path** : `/optimizer`

#### GET - Health Check
```
GET {{base_url}}/optimizer/health
```

**Réponse attendue** :
```json
{
  "status": "UP",
  "service": "optimizer-service",
  "message": "Service opérationnel et prêt à recevoir les alertes"
}
```

#### GET - Informations du service
```
GET {{base_url}}/optimizer/info
```

**Réponse attendue** :
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

### 4. Device Simulator Service

**Base Path** : `/devices`

#### GET - Liste des appareils simulés
```
GET {{base_url}}/devices/devices
```

**Réponse attendue** :
```json
[
  {
    "id": "device-1",
    "name": "Réfrigérateur",
    "powerKw": 0.5,
    "status": "ON"
  },
  {
    "id": "device-2",
    "name": "Lave-linge",
    "powerKw": 0.8,
    "status": "ON"
  }
]
```

---

### 5. Services de Monitoring

#### Prometheus
```
GET {{base_url}}/prometheus
```

#### Grafana
```
GET {{base_url}}/grafana
```

#### RabbitMQ Management
```
GET {{base_url}}/rabbitmq
```

**Note** : Pour RabbitMQ, vous devrez vous connecter avec les identifiants configurés dans les secrets Kubernetes.

---

## 📋 Exemple de Collection Postman Complète

### Structure recommandée

```
Smart Home Load Balancer
├── Usage Collector
│   ├── GET Current Usage
│   ├── GET History
│   ├── GET Devices
│   └── POST Save Snapshot
├── Optimizer
│   ├── GET Health
│   └── GET Info
├── Device Simulator
│   └── GET Devices
└── Monitoring
    ├── Prometheus
    ├── Grafana
    └── RabbitMQ
```

## 🔧 Configuration des Variables Postman

### Variables d'Environnement

Créez un environnement dans Postman avec :

| Variable | Valeur | Description |
|----------|--------|-------------|
| `base_url` | `http://smarthome.local` | URL de base (ou IP Minikube) |
| `host_header` | `smarthome.local` | Header Host (si méthode 2) |

### Variables de Collection

| Variable | Valeur Initiale | Description |
|----------|-----------------|-------------|
| `base_url` | `http://smarthome.local` | URL de base par défaut |

## 🧪 Tests Automatisés (Scripts Postman)

### Test pour GET /usage/current

Dans l'onglet **Tests** de la requête :

```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has totalPowerKw", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('totalPowerKw');
    pm.expect(jsonData.totalPowerKw).to.be.a('number');
});

pm.test("Response has devices", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('devices');
    pm.expect(jsonData.devices).to.be.an('object');
});
```

### Test pour GET /optimizer/health

```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Service is UP", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.status).to.eql("UP");
    pm.expect(jsonData.service).to.eql("optimizer-service");
});
```

## 🐛 Dépannage

### Erreur : Minikube n'est pas démarré

Si vous obtenez l'erreur `The control-plane node minikube host does not exist` :

#### Solution 1 : Démarrer Minikube en tant qu'administrateur (Recommandé)

1. **Fermer PowerShell actuel**

2. **Ouvrir PowerShell en tant qu'administrateur** :
   - Clic droit sur PowerShell dans le menu Démarrer
   - Sélectionner "Exécuter en tant qu'administrateur"

3. **Naviguer vers le projet** :
   ```powershell
   cd D:\Salma\smart-home-load-balancer
   ```

4. **Démarrer Minikube** :
   ```powershell
   minikube start
   ```

5. **Vérifier que Minikube est démarré** :
   ```powershell
   minikube status
   minikube ip
   ```

#### Solution 2 : Utiliser Docker Desktop comme driver

Si vous avez Docker Desktop installé, vous pouvez utiliser le driver Docker :

```powershell
# Supprimer le profil existant (si nécessaire)
minikube delete

# Démarrer avec Docker driver
minikube start --driver=docker
```

#### Solution 3 : Alternative avec Docker Compose (sans Kubernetes)

Si vous ne pouvez pas démarrer Minikube, vous pouvez tester les services directement avec Docker Compose :

1. **Lancer les services** :
   ```powershell
   docker-compose up -d
   ```

2. **Tester directement avec Postman** :
   - Usage Collector : `http://localhost:8083/usage/current`
   - Device Simulator : `http://localhost:8082/devices`
   - RabbitMQ : `http://localhost:15672`

**Note** : Cette méthode ne nécessite pas Kubernetes ni Ingress, mais les services seront accessibles directement sur localhost.

### Erreur : "Connection refused" ou "Unable to connect"

1. **Vérifiez que l'Ingress est actif** :
   ```powershell
   kubectl get ingress -n smarthome
   ```

2. **Vérifiez que les services sont en cours d'exécution** :
   ```powershell
   kubectl get pods -n smarthome
   ```

3. **Vérifiez l'IP de Minikube** :
   ```powershell
   minikube ip
   ```

4. **Si vous utilisez la méthode 2 (IP + Header)** :
   - Assurez-vous que le header `Host: smarthome.local` est présent dans chaque requête

### Erreur : "404 Not Found"

1. **Vérifiez le chemin** : L'Ingress utilise `rewrite-target: /`, donc les chemins doivent correspondre exactement
2. **Vérifiez que le service est déployé** :
   ```powershell
   kubectl get svc -n smarthome
   ```

### Erreur : "502 Bad Gateway"

1. **Vérifiez que les pods sont prêts** :
   ```powershell
   kubectl get pods -n smarthome
   ```

2. **Vérifiez les logs du service** :
   ```powershell
   kubectl logs -n smarthome deployment/usage-collector-service
   ```

## 📊 Exemple de Workflow de Test Complet

1. **Tester la santé des services** :
   - `GET /optimizer/health`
   - `GET /peak/actuator/health`

2. **Récupérer les appareils** :
   - `GET /devices/devices`

3. **Vérifier la consommation actuelle** :
   - `GET /usage/current`

4. **Sauvegarder un snapshot** :
   - `POST /usage/save`

5. **Consulter l'historique** :
   - `GET /usage/history?limit=10`

## 💡 Astuces

1. **Utilisez des variables** : Créez des variables Postman pour éviter de répéter l'URL
2. **Sauvegardez les réponses** : Créez des exemples de réponses pour la documentation
3. **Tests automatiques** : Utilisez les scripts de test pour valider automatiquement les réponses
4. **Environnements multiples** : Créez des environnements pour dev/staging/prod

## 🔗 Liens Utiles

- [Documentation Postman](https://learning.postman.com/docs/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
