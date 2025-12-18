# Requêtes POST Valides dans le Projet

Ce document liste toutes les requêtes POST disponibles dans le projet Smart Home Load Balancer.

## 📋 Résumé

**Nombre total d'endpoints POST** : **1**

---

## 1. Usage Collector Service - Sauvegarder un Snapshot

### Endpoint
```
POST /usage/save
```

### URL Complète

**Via Ingress Kubernetes** :
```
POST http://smarthome.local/usage/save
```

**Via Docker Compose (local)** :
```
POST http://localhost:8083/usage/save
```

**Via Port Forward Kubernetes** :
```
POST http://localhost:8083/usage/save
```

### Méthode HTTP
`POST`

### Headers Requis
- Aucun header spécifique requis
- `Content-Type: application/json` (optionnel, car pas de body)

### Body
**Aucun body requis** - Cet endpoint ne prend pas de paramètres dans le corps de la requête.

### Description
Sauvegarde un snapshot de l'état actuel de la consommation énergétique dans la base de données PostgreSQL. L'endpoint :
1. Récupère automatiquement les données actuelles depuis le service d'agrégation (`UsageAggregationService`)
2. Calcule la consommation totale actuelle
3. Enregistre un nouvel enregistrement `HomeUsage` dans PostgreSQL avec un timestamp

### Réponse Succès (200 OK)

```json
{
  "message": "Snapshot sauvegardé avec succès",
  "totalPowerKw": 2.5
}
```

**Champs de la réponse** :
- `message` (String) : Message de confirmation
- `totalPowerKw` (Double) : Consommation totale en kilowatts au moment de la sauvegarde

### Exemple de Requête Postman

#### Configuration de la Requête

1. **Méthode** : `POST`
2. **URL** : `{{base_url}}/usage/save`
   - Où `{{base_url}}` = `http://smarthome.local` (Ingress) ou `http://localhost:8083` (Docker/local)

3. **Headers** :
   - Aucun header spécifique nécessaire
   - Postman ajoutera automatiquement `Content-Type: application/json` si vous laissez le body vide

4. **Body** :
   - Sélectionner : **None** (pas de body)
   - Ou laisser vide si vous utilisez "raw" avec JSON

#### Exemple avec cURL

```bash
curl -X POST http://smarthome.local/usage/save
```

Ou avec Docker Compose :
```bash
curl -X POST http://localhost:8083/usage/save
```

### Tests Postman

Dans l'onglet **Tests** de Postman, vous pouvez ajouter :

```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has message", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('message');
    pm.expect(jsonData.message).to.include('sauvegardé');
});

pm.test("Response has totalPowerKw", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('totalPowerKw');
    pm.expect(jsonData.totalPowerKw).to.be.a('number');
    pm.expect(jsonData.totalPowerKw).to.be.at.least(0);
});
```

### Vérification après l'Appel

Après avoir appelé cet endpoint, vous pouvez vérifier que le snapshot a été sauvegardé :

```bash
GET {{base_url}}/usage/history?limit=1
```

Cette requête devrait retourner le snapshot que vous venez de sauvegarder en premier dans la liste.

### Code Source

**Fichier** : `usage-collector-service/src/main/java/com/smarthome/usagecollectorservice/controller/UsageController.java`

```java
@PostMapping("/save")
public ResponseEntity<Map<String, Object>> saveSnapshot() {
    usageAggregationService.saveCurrentSnapshot();
    Map<String, Object> response = new HashMap<>();
    response.put("message", "Snapshot sauvegardé avec succès");
    response.put("totalPowerKw", usageAggregationService.getCurrentTotalPowerKw());
    return ResponseEntity.ok(response);
}
```

---

## 📝 Notes Importantes

1. **Pas d'authentification** : Actuellement, cet endpoint n'a pas d'authentification configurée
2. **Pas de validation** : Aucun paramètre à valider car aucun body n'est requis
3. **Idempotence** : Vous pouvez appeler cet endpoint plusieurs fois - chaque appel créera un nouveau snapshot avec un nouveau timestamp
4. **Dépendances** : 
   - Nécessite que le service `UsageAggregationService` soit opérationnel
   - Nécessite une connexion active à PostgreSQL
   - Nécessite que des données soient disponibles depuis RabbitMQ (via Device Simulator)

---

## 🔍 Endpoints POST Non Disponibles

Les services suivants **n'ont pas d'endpoints POST** :

- **Optimizer Service** : Seulement des GET (`/health`, `/info`)
- **Peak Detector Service** : Pas de contrôleur REST (fonctionne en arrière-plan via RabbitMQ)
- **Device Simulator Service** : Seulement un GET (`/devices`)

---

## 🚀 Workflow Recommandé

1. **Vérifier la consommation actuelle** :
   ```
   GET /usage/current
   ```

2. **Sauvegarder un snapshot** :
   ```
   POST /usage/save
   ```

3. **Vérifier l'historique** :
   ```
   GET /usage/history?limit=10
   ```

4. **Vérifier que le snapshot a été sauvegardé** :
   Le premier élément de l'historique devrait être celui que vous venez de sauvegarder.

---

## 📚 Ressources

- **Contrôleur** : `UsageController.java`
- **Service** : `UsageAggregationService.java`
- **Modèle** : `HomeUsage.java`
- **Repository** : `HomeUsageRepository.java`

