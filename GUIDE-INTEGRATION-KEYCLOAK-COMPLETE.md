# Guide Complet : Intégrer Keycloak dans Minikube

**État actuel** : Frontend et Backend accessibles via `minikube service frontend-service-nodeport -n smarthome`

**Objectif** : Intégrer Keycloak pour l'authentification

---

## 📋 ÉTAPE 1 : Vérifier les Prérequis

```bash
# Vérifier que Minikube est actif
minikube status

# Vérifier que le namespace existe
kubectl get namespace smarthome

# Vérifier que PostgreSQL est déployé
kubectl get pods -n smarthome -l app=postgres

# Vérifier que le secret PostgreSQL existe
kubectl get secret postgres-secret -n smarthome
```

**Si le secret n'existe pas**, créez-le :
```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=smarthome \
  -n smarthome
```

---

## 🗄️ ÉTAPE 2 : Créer la Base de Données Keycloak

### ⚠️ Solution Recommandée : Utiliser kubectl exec (Pas besoin de port-forward)

**Cette méthode fonctionne même si le port 5432 est déjà utilisé localement.**

```powershell
# Méthode qui fonctionne : Utiliser sh -c avec PGPASSWORD
# Obtenir le nom du pod PostgreSQL
$POSTGRES_POD = kubectl get pod -n smarthome -l app=postgres -o jsonpath='{.items[0].metadata.name}'

# Créer la base de données (méthode qui fonctionne)
kubectl exec -n smarthome $POSTGRES_POD -- sh -c "PGPASSWORD=smarthome psql -U smarthome -d smarthome -c 'CREATE DATABASE keycloak;'"

# Si vous obtenez "database already exists", c'est normal, la base existe déjà

# Vérifier que la base de données a été créée
kubectl exec -n smarthome $POSTGRES_POD -- sh -c "PGPASSWORD=smarthome psql -U smarthome -d smarthome -c '\l'" | Select-String "keycloak"
```

**En une seule ligne (PowerShell)** :
```powershell
kubectl exec -n smarthome (kubectl get pod -n smarthome -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- sh -c "PGPASSWORD=smarthome psql -U smarthome -d smarthome -c 'CREATE DATABASE keycloak;'"
```

**Note** : Remplacez `smarthome` par le mot de passe réel de votre secret PostgreSQL si différent.

**Si vous obtenez une erreur "database already exists"**, c'est normal, la base existe déjà.

### Alternative : Port-forward sur un autre port

Si vous préférez utiliser `psql` localement, utilisez un port différent :

```bash
# Terminal 1 : Port-forward sur un port différent (ex: 5433)
kubectl port-forward -n smarthome svc/postgres-service 5433:5432

# Terminal 2 : Se connecter avec le nouveau port
psql -h localhost -p 5433 -U smarthome -d smarthome

# Dans psql, exécutez :
CREATE DATABASE keycloak;

# Vérifier
\l

# Quitter
\q
```

### Vérifier quel processus utilise le port 5432 (Windows PowerShell)

```powershell
# Voir quel processus utilise le port 5432
netstat -ano | findstr :5432

# Ou avec Get-NetTCPConnection (PowerShell)
Get-NetTCPConnection -LocalPort 5432 | Select-Object LocalAddress, LocalPort, State, OwningProcess

# Pour arrêter le processus (remplacez PID par le numéro du processus)
# Stop-Process -Id PID
```

**Note** : Si vous avez PostgreSQL installé localement, vous pouvez soit l'arrêter temporairement, soit utiliser la méthode `kubectl exec` ci-dessus qui ne nécessite pas de port-forward.

---

## 🔐 ÉTAPE 3 : Créer le Secret Keycloak

```bash
kubectl create secret generic keycloak-secret \
  --from-literal=username=admin \
  --from-literal=password=admin123 \
  -n smarthome

# Vérifier
kubectl get secret keycloak-secret -n smarthome
```

---

## 📦 ÉTAPE 4 : Déployer Keycloak

```bash
# Déployer Keycloak
kubectl apply -f k8s/keycloak/keycloak-deployment.yaml
kubectl apply -f k8s/keycloak/keycloak-service.yaml

# Vérifier le déploiement
kubectl get pods -n smarthome -l app=keycloak

# Attendre que le pod soit prêt (peut prendre 2-3 minutes)
kubectl wait --for=condition=ready pod -l app=keycloak -n smarthome --timeout=300s

# Vérifier les logs
kubectl logs -n smarthome -l app=keycloak --tail=30
```

**⚠️ Important** : Attendez de voir dans les logs : `Keycloak started` ou `Listening on`

---

## 🌐 ÉTAPE 5 : Accéder à Keycloak

### Option A : Via NodePort (Comme votre frontend)

```bash
# Obtenir l'URL Keycloak
minikube service keycloak-service -n smarthome --url

# Ou directement dans le navigateur
# http://$(minikube ip):30080
```

### Option B : Via Port-Forward

```bash
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
# Puis ouvrir http://localhost:8080
```

**Ouvrez Keycloak dans votre navigateur** et vérifiez que la page d'accueil s'affiche.

---

## ⚙️ ÉTAPE 6 : Configuration Initiale de Keycloak

### 6.1. Se connecter à la Console d'Administration

1. Sur la page d'accueil Keycloak, cliquez sur **"Administration Console"**
2. Connectez-vous avec :
   - **Username** : `admin`
   - **Password** : `admin123`

### 6.2. Créer le Realm "smarthome"

1. Dans le menu déroulant en haut à gauche (actuellement "Master"), cliquez dessus
2. Cliquez sur **"Create Realm"** (ou le bouton "+" à côté de "Master")
3. Entrez le nom : **`smarthome`**
4. Cliquez sur **"Create"**

### 6.3. Vérifier le Realm

1. Assurez-vous que **"smarthome"** est sélectionné dans le menu déroulant en haut
2. Allez dans **Realm Settings** > **General**
3. Vérifiez que **"Enabled"** est sur **ON**

---

## 🔑 ÉTAPE 7 : Créer les Clients OAuth2

### 7.1. Client pour le Frontend (Public)

1. Dans le menu de gauche, cliquez sur **"Clients"**
2. Cliquez sur **"Create client"** (bouton en haut à droite)
3. Remplissez :
   - **Client type** : `OpenID Connect`
   - **Client ID** : `frontend-client`
   - Cliquez sur **"Next"**

4. Configuration :
   - ❌ **Client authentication** : `OFF` (client public)
   - ❌ **Authorization** : `OFF`
   - ✅ **Standard flow** : `ON`
   - ✅ **Direct access grants** : `ON` (pour les tests)
   - ❌ **Implicit flow** : `OFF`
   - Cliquez sur **"Next"**

5. Configuration des URLs :
   - **Root URL** : `http://$(minikube ip):30000` (remplacez par l'IP de votre Minikube)
   - **Valid redirect URIs** : 
     - `http://$(minikube ip):30000/*`
     - `http://localhost:30000/*`
     - `http://localhost:3000/*`
   - **Web origins** : `*`
   - Cliquez sur **"Save"**

### 7.2. Client pour les Microservices Backend

1. Créez un nouveau client : **"Create client"**
2. **Client ID** : `microservices-client`
3. Configuration :
   - ✅ **Client authentication** : `ON`
   - ❌ **Authorization** : `OFF`
   - ✅ **Standard flow** : `ON`
   - ✅ **Direct access grants** : `ON`
   - Cliquez sur **"Next"**

4. URLs :
   - **Root URL** : `http://api-gateway-service:80`
   - **Valid redirect URIs** : `http://api-gateway-service:80/*`
   - **Web origins** : `*`
   - Cliquez sur **"Save"**

5. **IMPORTANT** : Notez le **Client Secret**
   - Allez dans l'onglet **"Credentials"**
   - Copiez le **"Client secret"** (vous en aurez besoin) Ond2I6qI6aJsfPD8ewgFiSu5LSoSFM2e

### 7.3. Client de Test (Optionnel mais recommandé)

1. Créez un client : **"Create client"**
2. **Client ID** : `test-client`
3. Configuration :
   - ❌ **Client authentication** : `OFF`
   - ✅ **Direct access grants** : `ON`
   - Cliquez sur **"Next"**

4. URLs :
   - **Valid redirect URIs** : `http://localhost:8080/*`
   - **Web origins** : `*`
   - Cliquez sur **"Save"**

---

## 👤 ÉTAPE 8 : Créer un Utilisateur de Test

1. Dans le menu de gauche, cliquez sur **"Users"**
2. Cliquez sur **"Create new user"** (bouton en haut à droite)
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

---

## 🔄 ÉTAPE 9 : Reconstruire les Images Docker avec Keycloak

**⚠️ IMPORTANT** : Vous devez reconstruire les images car nous avons ajouté les dépendances OAuth2.

### 9.1. Usage Collector Service

```bash
cd usage-collector-service

# Reconstruire l'image
docker build -t salmaidoufkir/usage-collector-service:latest .

# Push vers Docker Hub (ou votre registry)
docker push salmaidoufkir/usage-collector-service:latest

cd ..
```

### 9.2. Peak Detector Service

```bash
cd peak-detector-service
docker build -t salmaidoufkir/peak-detector-service:latest .
docker push salmaidoufkir/peak-detector-service:latest
cd ..
```

### 9.3. Optimizer Service

```bash
cd optimizer-service
docker build -t salmaidoufkir/optimizer-service:latest .
docker push salmaidoufkir/optimizer-service:latest
cd ..
```

### 9.4. Device Simulator Service

```bash
cd device-simulator-service
docker build -t salmaidoufkir/device-simulator-service:latest .
docker push salmaidoufkir/device-simulator-service:latest
cd ..
```

---

## 🚀 ÉTAPE 10 : Redéployer les Services dans Kubernetes

### Option A : Utiliser kubectl apply (Recommandé si vous avez modifié les YAML)

Si vous avez modifié les fichiers YAML (ajout des variables Keycloak), utilisez `kubectl apply` :

```bash
# Appliquer les configurations mises à jour
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/device-simulator/deployment.yaml

# Attendre que les déploiements soient terminés
kubectl rollout status deployment/usage-collector-service -n smarthome
kubectl rollout status deployment/peak-detector-service -n smarthome
kubectl rollout status deployment/optimizer-service -n smarthome
kubectl rollout status deployment/device-simulator-service -n smarthome

# Vérifier que les pods sont prêts
kubectl get pods -n smarthome
```

**Pourquoi cette approche fonctionne** :
- Les fichiers YAML ont été modifiés (ajout des variables `KEYCLOAK_URL` et `KEYCLOAK_REALM`)
- Kubernetes détecte le changement et redéploie automatiquement
- Avec `imagePullPolicy: Always`, Kubernetes pull la nouvelle image Docker

### Option B : Utiliser kubectl rollout restart (Alternative)

Si vous préférez forcer le redéploiement sans modifier les YAML :

```bash
# Forcer le redéploiement pour utiliser les nouvelles images
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome

# Attendre que les déploiements soient terminés
kubectl rollout status deployment/usage-collector-service -n smarthome
kubectl rollout status deployment/peak-detector-service -n smarthome
kubectl rollout status deployment/optimizer-service -n smarthome
kubectl rollout status deployment/device-simulator-service -n smarthome

# Vérifier que les pods sont prêts
kubectl get pods -n smarthome
```

**Quand utiliser cette approche** :
- Quand vous avez seulement reconstruit l'image Docker (même tag `:latest`)
- Quand vous voulez forcer un redéploiement sans changer le YAML
- Quand vous n'êtes pas sûr que Kubernetes détectera le changement

### ⚠️ Différence importante

| Commande | Quand l'utiliser | Avantage |
|----------|------------------|----------|
| `kubectl apply -f` | Quand vous avez modifié les fichiers YAML | Applique les changements de configuration |
| `kubectl rollout restart` | Quand vous voulez juste redémarrer avec la nouvelle image | Force le redéploiement même sans changement YAML |

**Dans votre cas** : Comme nous avons modifié les YAML (ajout des variables Keycloak), **`kubectl apply -f` est la meilleure approche** car elle applique les changements de configuration ET redéploie avec la nouvelle image (grâce à `imagePullPolicy: Always`).

---

## 🧪 ÉTAPE 11 : Tester l'Authentification

### 11.1. Obtenir l'URL de Keycloak

```bash
# Obtenir l'IP de Minikube
MINIKUBE_IP=$(minikube ip)
echo "Keycloak URL: http://$MINIKUBE_IP:30080"
```

### 11.2. Obtenir un Token d'Accès

```bash
# Obtenir l'IP de Minikube
MINIKUBE_IP=$(minikube ip)

# Obtenir un token pour l'utilisateur testuser
TOKEN=$(curl -s -X POST "http://$MINIKUBE_IP:30080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=test-client" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password" | jq -r '.access_token')

echo "Token obtenu: ${TOKEN:0:50}..."
```

**Si vous n'avez pas `jq`**, utilisez cette version :

```bash
MINIKUBE_IP=$(minikube ip)
RESPONSE=$(curl -s -X POST "http://$MINIKUBE_IP:30080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=test-client" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password")

# Extraire le token manuellement (Windows PowerShell)
# Ou utilisez un outil JSON en ligne pour extraire access_token
```

### 11.3. Tester un Endpoint Protégé

```bash
# Obtenir l'URL du service (via NodePort ou port-forward)
# Option 1: Via port-forward
kubectl port-forward -n smarthome svc/usage-collector-service 8083:8083

# Dans un autre terminal, tester avec le token
curl -X GET "http://localhost:8083/usage/current" \
  -H "Authorization: Bearer $TOKEN" \
  -v
```

**Résultat attendu** : `200 OK` avec les données JSON

### 11.4. Tester sans Token (Doit échouer)

```bash
# Tester sans token
curl -X GET "http://localhost:8083/usage/current" -v
```

**Résultat attendu** : `401 Unauthorized`

### 11.5. Tester l'Endpoint Health (Doit être accessible)

```bash
# L'endpoint health doit être accessible sans authentification
curl -X GET "http://localhost:8083/actuator/health" -v
```

**Résultat attendu** : `200 OK` avec `{"status":"UP"}`

---

## 🔍 ÉTAPE 12 : Vérifier les Logs

```bash
# Vérifier que les services se connectent à Keycloak
kubectl logs -n smarthome deployment/usage-collector-service --tail=50

# Rechercher les erreurs liées à Keycloak
kubectl logs -n smarthome deployment/usage-collector-service | grep -i "keycloak\|oauth\|jwt\|security"

# Vérifier les autres services
kubectl logs -n smarthome deployment/peak-detector-service --tail=30
kubectl logs -n smarthome deployment/optimizer-service --tail=30
```

---

## 🎯 ÉTAPE 13 : Tester avec le Frontend

### 13.1. Obtenir l'URL du Frontend

```bash
minikube service frontend-service-nodeport -n smarthome --url
```

### 13.2. Configurer le Frontend pour Keycloak

Vous devrez modifier votre frontend pour :
1. Intégrer la bibliothèque Keycloak JS
2. Initialiser Keycloak avec l'URL : `http://$(minikube ip):30080`
3. Gérer l'authentification et les tokens
4. Inclure le token dans les requêtes vers le backend

**Exemple de configuration Keycloak dans le frontend** :

```javascript
import Keycloak from 'keycloak-js';

const keycloak = new Keycloak({
  url: 'http://VOTRE_MINIKUBE_IP:30080',
  realm: 'smarthome',
  clientId: 'frontend-client'
});

keycloak.init({ onLoad: 'login-required' }).then((authenticated) => {
  if (authenticated) {
    console.log('Authentifié!');
    // Utiliser keycloak.token pour les requêtes API
  }
});
```

---

## 📊 Checklist de Vérification

- [ ] PostgreSQL déployé et accessible
- [ ] Base de données `keycloak` créée
- [ ] Secret `keycloak-secret` créé
- [ ] Keycloak déployé et accessible via NodePort
- [ ] Realm `smarthome` créé dans Keycloak
- [ ] Client `frontend-client` créé
- [ ] Client `microservices-client` créé
- [ ] Utilisateur `testuser` créé
- [ ] Images Docker reconstruites avec OAuth2
- [ ] Services redéployés dans Kubernetes
- [ ] Token obtenu avec succès
- [ ] Endpoint protégé retourne 401 sans token
- [ ] Endpoint protégé retourne 200 avec token
- [ ] Endpoint health accessible sans authentification

---

## 🐛 Dépannage

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

1. Vérifiez que Keycloak est accessible :
   ```bash
   MINIKUBE_IP=$(minikube ip)
   curl "http://$MINIKUBE_IP:30080/realms/smarthome/.well-known/openid-configuration"
   ```

2. Vérifiez les credentials de l'utilisateur dans Keycloak
3. Vérifiez que le client a "Direct access grants" activé

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

3. Vérifiez les logs du service pour les erreurs JWT

### Problème : Les services ne démarrent pas

```bash
# Vérifier les logs de démarrage
kubectl logs -n smarthome deployment/usage-collector-service

# Vérifier les événements
kubectl describe pod -n smarthome -l app=usage-collector-service
```

---

## 🎉 Félicitations !

Keycloak est maintenant intégré dans votre architecture. Tous vos endpoints backend sont protégés par authentification JWT, sauf les endpoints Actuator health/info qui restent accessibles pour le monitoring.

**Prochaines étapes** :
- Intégrer Keycloak dans votre frontend
- Configurer les rôles et permissions
- Implémenter le refresh token
- Configurer HTTPS pour la production

