# Guide Pratique : Déployer et Tester Keycloak dans Minikube

Ce guide vous donne les étapes exactes pour déployer Keycloak et tester l'authentification avec vos microservices.

## 📋 Prérequis

Vérifiez que vous avez :
- ✅ Minikube démarré : `minikube status`
- ✅ Namespace `smarthome` créé : `kubectl get namespace smarthome`
- ✅ PostgreSQL déployé et fonctionnel
- ✅ Secrets PostgreSQL créés

## 🚀 ÉTAPE 1 : Préparer la Base de Données Keycloak

### 1.1. Créer la base de données dans PostgreSQL

```bash
# Port-forward vers PostgreSQL
kubectl port-forward -n smarthome svc/postgres-service 5432:5432
```

**Dans un NOUVEAU terminal** (gardez le port-forward actif) :

```bash
# Se connecter à PostgreSQL
psql -h localhost -U smarthome -d smarthome

# Dans psql, créer la base de données Keycloak
CREATE DATABASE keycloak;

# Vérifier
\l

# Quitter
\q
```

## 🔐 ÉTAPE 2 : Créer le Secret Keycloak

```bash
kubectl create secret generic keycloak-secret \
  --from-literal=username=admin \
  --from-literal=password=admin123 \
  -n smarthome

# Vérifier
kubectl get secret keycloak-secret -n smarthome
```

## 📦 ÉTAPE 3 : Déployer Keycloak

```bash
# Déployer Keycloak
kubectl apply -f k8s/keycloak/keycloak-deployment.yaml
kubectl apply -f k8s/keycloak/keycloak-service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=keycloak

# Attendre que le pod soit "Running" (peut prendre 2-3 minutes)
kubectl wait --for=condition=ready pod -l app=keycloak -n smarthome --timeout=300s

# Vérifier les logs
kubectl logs -n smarthome -l app=keycloak --tail=20
```

**⚠️ Important** : Attendez que Keycloak soit complètement démarré. Vous verrez dans les logs : `Keycloak started` ou `Listening on`.

## 🌐 ÉTAPE 4 : Accéder à Keycloak

### Option A : Port-Forward (Recommandé)

```bash
# Dans un nouveau terminal
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
```

Ouvrez votre navigateur : **http://localhost:8080**

### Option B : Via Minikube IP (NodePort)

Si vous préférez utiliser NodePort, modifiez temporairement le service :

```bash
kubectl patch svc keycloak-service -n smarthome -p '{"spec":{"type":"NodePort"}}'
kubectl patch svc keycloak-service -n smarthome -p '{"spec":{"ports":[{"port":8080,"targetPort":8080,"nodePort":30080}]}}'

# Obtenir l'URL
minikube service keycloak-service -n smarthome --url
```

## ⚙️ ÉTAPE 5 : Configuration Initiale de Keycloak

### 5.1. Se connecter à la Console d'Administration

1. Ouvrez http://localhost:8080 dans votre navigateur
2. Cliquez sur **"Administration Console"**
3. Connectez-vous avec :
   - **Username** : `admin`
   - **Password** : `admin123` (celui que vous avez mis dans le secret)

### 5.2. Créer le Realm "smarthome"

1. Dans le menu déroulant en haut à gauche, cliquez sur **"Master"**
2. Cliquez sur **"Create Realm"** (ou le bouton "+" à côté de "Master")
3. Entrez le nom : **`smarthome`**
4. Cliquez sur **"Create"**

### 5.3. Vérifier la Configuration du Realm

1. Assurez-vous que le realm **"smarthome"** est sélectionné (menu déroulant en haut)
2. Allez dans **Realm Settings** > **General**
3. Vérifiez que **"Enabled"** est sur **ON**

## 🔑 ÉTAPE 6 : Créer un Client OAuth2

### 6.1. Créer le Client pour les Microservices

1. Dans le menu de gauche, cliquez sur **"Clients"**
2. Cliquez sur **"Create client"** (ou le bouton "Create" en haut)
3. Remplissez :
   - **Client type** : `OpenID Connect`
   - **Client ID** : `microservices-client`
   - Cliquez sur **"Next"**

4. Configuration :
   - ✅ **Client authentication** : `ON`
   - ✅ **Authorization** : `OFF`
   - ✅ **Standard flow** : `ON`
   - ✅ **Direct access grants** : `ON` (pour les tests)
   - Cliquez sur **"Next"**

5. Configuration des URLs :
   - **Root URL** : `http://api-gateway-service:80`
   - **Valid redirect URIs** : `http://api-gateway-service:80/*`, `http://localhost:8080/*`
   - **Web origins** : `*`
   - Cliquez sur **"Save"**

6. **IMPORTANT** : Notez le **Client Secret**
   - Allez dans l'onglet **"Credentials"**
   - Copiez le **"Client secret"** (vous en aurez besoin pour les tests)

### 6.2. Créer un Client Public pour les Tests

1. Créez un nouveau client : **"Create client"**
2. **Client ID** : `test-client`
3. Configuration :
   - **Client authentication** : `OFF` (client public)
   - **Standard flow** : `ON`
   - **Direct access grants** : `ON`
   - **Implicit flow** : `OFF`
4. URLs :
   - **Valid redirect URIs** : `http://localhost:8080/*`, `http://localhost:3000/*`
   - **Web origins** : `*`
5. Cliquez sur **"Save"**

## 👤 ÉTAPE 7 : Créer un Utilisateur de Test

1. Dans le menu de gauche, cliquez sur **"Users"**
2. Cliquez sur **"Create new user"** (ou le bouton "Add user")
3. Remplissez :
   - **Username** : `testuser`
   - **Email** : `test@example.com`
   - ✅ **Email verified** : `ON`
   - ✅ **Enabled** : `ON`
   - Cliquez sur **"Create"**

4. Allez dans l'onglet **"Credentials"**
5. Cliquez sur **"Set password"**
6. Remplissez :
   - **Password** : `testpassword`
   - **Password confirmation** : `testpassword`
   - ❌ **Temporary** : `OFF` (décochez)
   - Cliquez sur **"Save"**

## 🧪 ÉTAPE 8 : Tester l'Authentification

### 8.1. Obtenir un Token d'Accès (Password Grant)

```bash
# Obtenir un token pour l'utilisateur testuser
curl -X POST "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=test-client" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password"
```

**Réponse attendue** :
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "...",
  "token_type": "Bearer",
  "scope": "profile email"
}
```

**Copiez le `access_token`** pour l'étape suivante.

### 8.2. Obtenir un Token (Client Credentials - pour les services)

```bash
# Remplacez CLIENT_SECRET par le secret que vous avez noté
curl -X POST "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=microservices-client" \
  -d "client_secret=VOTRE_CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

### 8.3. Tester un Endpoint Protégé

**Avant de tester**, assurez-vous que vos services sont redéployés avec Keycloak (voir ÉTAPE 9).

```bash
# Remplacez VOTRE_TOKEN par le token obtenu précédemment
TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."

# Tester l'endpoint usage-collector
curl -X GET "http://localhost:8083/usage/current" \
  -H "Authorization: Bearer $TOKEN" \
  -v
```

**Si vous obtenez une erreur 401**, c'est normal si les services ne sont pas encore redéployés.

**Si vous obtenez une erreur 403**, vérifiez que le token est valide.

## 🔄 ÉTAPE 9 : Reconstruire et Redéployer les Services

### 9.1. Reconstruire les Images Docker

```bash
# Usage Collector Service
cd usage-collector-service
docker build -t salmaidoufkir/usage-collector-service:latest .
docker push salmaidoufkir/usage-collector-service:latest
cd ..

# Peak Detector Service
cd peak-detector-service
docker build -t salmaidoufkir/peak-detector-service:latest .
docker push salmaidoufkir/peak-detector-service:latest
cd ..

# Optimizer Service
cd optimizer-service
docker build -t salmaidoufkir/optimizer-service:latest .
docker push salmaidoufkir/optimizer-service:latest
cd ..

# Device Simulator Service
cd device-simulator-service
docker build -t salmaidoufkir/device-simulator-service:latest .
docker push salmaidoufkir/device-simulator-service:latest
cd ..
```

### 9.2. Redéployer dans Kubernetes

```bash
# Redémarrer les déploiements pour prendre en compte les nouvelles images
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome

# Attendre que les pods soient prêts
kubectl rollout status deployment/usage-collector-service -n smarthome
kubectl rollout status deployment/peak-detector-service -n smarthome
kubectl rollout status deployment/optimizer-service -n smarthome
kubectl rollout status deployment/device-simulator-service -n smarthome
```

### 9.3. Vérifier les Logs

```bash
# Vérifier que les services se connectent à Keycloak
kubectl logs -n smarthome deployment/usage-collector-service --tail=50

# Rechercher les erreurs
kubectl logs -n smarthome deployment/usage-collector-service | grep -i "keycloak\|oauth\|jwt\|security"
```

## ✅ ÉTAPE 10 : Test Complet

### 10.1. Tester sans Token (Doit échouer)

```bash
# Port-forward vers usage-collector
kubectl port-forward -n smarthome svc/usage-collector-service 8083:8083

# Dans un autre terminal, tester sans token
curl -X GET "http://localhost:8083/usage/current" -v
```

**Résultat attendu** : `401 Unauthorized`

### 10.2. Tester avec Token (Doit réussir)

```bash
# Obtenir un nouveau token
TOKEN=$(curl -s -X POST "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=test-client" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password" | jq -r '.access_token')

# Tester avec le token
curl -X GET "http://localhost:8083/usage/current" \
  -H "Authorization: Bearer $TOKEN" \
  -v
```

**Résultat attendu** : `200 OK` avec les données JSON

### 10.3. Tester les Endpoints Actuator (Doivent être accessibles)

```bash
# Les endpoints health doivent être accessibles sans authentification
curl -X GET "http://localhost:8083/actuator/health" -v
```

**Résultat attendu** : `200 OK` avec `{"status":"UP"}`

## 🎯 Script de Test Complet

Créez un fichier `test-keycloak.sh` :

```bash
#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
REALM="smarthome"
CLIENT_ID="test-client"
USERNAME="testuser"
PASSWORD="testpassword"

echo "🔑 Étape 1: Obtenir un token d'accès..."
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" \
  -d "grant_type=password" | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Erreur: Impossible d'obtenir le token"
  exit 1
fi

echo "✅ Token obtenu: ${TOKEN:0:50}..."

echo ""
echo "🧪 Étape 2: Tester l'endpoint protégé..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8083/usage/current" \
  -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
  echo "✅ Succès! Endpoint accessible avec authentification"
  echo "$BODY" | jq .
else
  echo "❌ Erreur HTTP $HTTP_CODE"
  echo "$BODY"
fi

echo ""
echo "🧪 Étape 3: Tester sans token (doit échouer)..."
RESPONSE_NO_TOKEN=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8083/usage/current")
HTTP_CODE_NO_TOKEN=$(echo "$RESPONSE_NO_TOKEN" | tail -n1)

if [ "$HTTP_CODE_NO_TOKEN" == "401" ]; then
  echo "✅ Correct! Endpoint protégé (401 Unauthorized)"
else
  echo "⚠️  Attendu 401, reçu $HTTP_CODE_NO_TOKEN"
fi

echo ""
echo "🧪 Étape 4: Tester l'endpoint health (doit être accessible)..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "http://localhost:8083/actuator/health")
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)

if [ "$HEALTH_CODE" == "200" ]; then
  echo "✅ Correct! Endpoint health accessible sans authentification"
else
  echo "⚠️  Attendu 200, reçu $HEALTH_CODE"
fi
```

Exécutez-le :

```bash
chmod +x test-keycloak.sh
./test-keycloak.sh
```

## 🐛 Dépannage Rapide

### Problème : Keycloak ne démarre pas

```bash
# Vérifier les logs
kubectl logs -n smarthome -l app=keycloak

# Vérifier que PostgreSQL est accessible
kubectl exec -n smarthome deployment/keycloak -- ping -c 3 postgres-service

# Vérifier les ressources
kubectl describe pod -n smarthome -l app=keycloak
```

### Problème : Impossible d'obtenir un token

1. Vérifiez que Keycloak est accessible : `curl http://localhost:8080/realms/smarthome/.well-known/openid-configuration`
2. Vérifiez les credentials de l'utilisateur
3. Vérifiez que le client est bien configuré avec "Direct access grants" activé

### Problème : 401 Unauthorized même avec un token

1. Vérifiez que les services peuvent contacter Keycloak :
   ```bash
   kubectl exec -n smarthome deployment/usage-collector-service -- \
     curl http://keycloak-service:8080/realms/smarthome/.well-known/openid-configuration
   ```

2. Vérifiez les variables d'environnement :
   ```bash
   kubectl exec -n smarthome deployment/usage-collector-service -- env | grep KEYCLOAK
   ```

3. Vérifiez les logs du service :
   ```bash
   kubectl logs -n smarthome deployment/usage-collector-service | grep -i "keycloak\|oauth\|jwt"
   ```

## 📊 Checklist Finale

- [ ] Keycloak déployé et accessible
- [ ] Realm `smarthome` créé
- [ ] Client `test-client` créé
- [ ] Utilisateur `testuser` créé
- [ ] Token obtenu avec succès
- [ ] Services redéployés
- [ ] Endpoint protégé retourne 401 sans token
- [ ] Endpoint protégé retourne 200 avec token
- [ ] Endpoint health accessible sans authentification

---

**🎉 Félicitations !** Keycloak est maintenant intégré et fonctionnel dans votre architecture microservices !


