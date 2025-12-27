# Guide d'Intégration Keycloak avec Minikube

Ce guide explique comment configurer et utiliser Keycloak pour l'authentification dans votre architecture microservices déployée sur Minikube.

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Déploiement de Keycloak](#déploiement-de-keycloak)
3. [Accès à Keycloak dans Minikube](#accès-à-keycloak-dans-minikube)
4. [Configuration du Realm](#configuration-du-realm)
5. [Configuration des Clients](#configuration-des-clients)
6. [Test de l'Authentification](#test-de-lauthentification)
7. [Intégration avec les Services](#intégration-avec-les-services)
8. [Dépannage](#dépannage)

## 🔧 Prérequis

- Minikube démarré et fonctionnel
- `kubectl` configuré pour utiliser Minikube
- Namespace `smarthome` créé
- Secrets PostgreSQL et Keycloak créés

## 🚀 Déploiement de Keycloak

### 1. Créer le Secret Keycloak

```bash
kubectl create secret generic keycloak-secret \
  --from-literal=username=admin \
  --from-literal=password=admin \
  -n smarthome
```

### 2. Créer la Base de Données Keycloak dans PostgreSQL

Connectez-vous à PostgreSQL et créez la base de données :

```bash
# Port-forward vers PostgreSQL
kubectl port-forward -n smarthome svc/postgres-service 5432:5432

# Dans un autre terminal, connectez-vous
psql -h localhost -U smarthome -d smarthome

# Créez la base de données Keycloak
CREATE DATABASE keycloak;
\q
```

### 3. Déployer Keycloak

```bash
kubectl apply -f k8s/keycloak/keycloak-deployment.yaml
kubectl apply -f k8s/keycloak/keycloak-service.yaml
```

### 4. Vérifier le Déploiement

```bash
# Vérifier que le pod Keycloak est en cours d'exécution
kubectl get pods -n smarthome -l app=keycloak

# Vérifier les logs
kubectl logs -n smarthome -l app=keycloak --tail=50
```

**Note :** Keycloak peut prendre 2-3 minutes pour démarrer complètement.

## 🌐 Accès à Keycloak dans Minikube

### Option 1 : Port-Forward (Recommandé pour le développement)

```bash
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
```

Accédez à Keycloak : http://localhost:8080

### Option 2 : Via Ingress (Si configuré)

Si vous avez configuré l'Ingress NGINX :

```bash
# Obtenir l'IP de Minikube
minikube ip

# Ajouter dans /etc/hosts (Linux/Mac) ou C:\Windows\System32\drivers\etc\hosts (Windows)
# <MINIKUBE_IP> smarthome.local

# Accéder via
http://smarthome.local/auth
```

### Option 3 : NodePort Service

Modifiez le service Keycloak pour utiliser NodePort :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: keycloak-service
  namespace: smarthome
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  selector:
    app: keycloak
```

Puis accédez via : `http://$(minikube ip):30080`

## ⚙️ Configuration du Realm

### 1. Connexion à la Console d'Administration

1. Ouvrez http://localhost:8080 (ou votre URL Keycloak)
2. Cliquez sur **Administration Console**
3. Connectez-vous avec :
   - **Username** : `admin`
   - **Password** : Le mot de passe défini dans le secret

### 2. Créer le Realm "smarthome"

1. Dans le menu déroulant en haut à gauche, cliquez sur **Master**
2. Cliquez sur **Create Realm**
3. Entrez le nom : `smarthome`
4. Cliquez sur **Create**

### 3. Configurer le Realm

#### 3.1. Paramètres Généraux

1. Allez dans **Realm Settings** > **General**
2. Vérifiez que :
   - **Realm name** : `smarthome`
   - **Enabled** : `ON`
   - **User-managed access** : `OFF`

#### 3.2. Configuration des Tokens

1. Allez dans **Realm Settings** > **Tokens**
2. Configurez :
   - **Access Token Lifespan** : `5 minutes` (ou selon vos besoins)
   - **SSO Session Idle** : `30 minutes`
   - **SSO Session Max** : `10 hours`

#### 3.3. Configuration des Endpoints

1. Allez dans **Realm Settings** > **Endpoints**
2. Notez l'URL du **OpenID Endpoint Configuration** :
   ```
   http://keycloak-service:8080/realms/smarthome/.well-known/openid-configuration
   ```

## 🔐 Configuration des Clients

Pour chaque microservice, vous devez créer un client OAuth2.

### 1. Créer un Client pour les Microservices

1. Allez dans **Clients** > **Create client**
2. Remplissez :
   - **Client type** : `OpenID Connect`
   - **Client ID** : `microservices-client` (ou un nom spécifique par service)
   - Cliquez sur **Next**

3. Configurez :
   - **Client authentication** : `ON` (pour les services backend)
   - **Authorization** : `OFF`
   - **Authentication flow** : `Standard flow`
   - Cliquez sur **Next**

4. Configuration des URLs :
   - **Root URL** : `http://api-gateway-service:80`
   - **Home URL** : `http://api-gateway-service:80`
   - **Valid redirect URIs** : `http://api-gateway-service:80/*`
   - **Web origins** : `*` (pour le développement)
   - Cliquez sur **Save**

5. Dans l'onglet **Credentials**, notez le **Client Secret**

### 2. Créer un Client Public pour le Frontend

1. Créez un nouveau client : `frontend-client`
2. Configuration :
   - **Client authentication** : `OFF` (client public)
   - **Standard flow** : `ON`
   - **Implicit flow** : `OFF`
   - **Direct access grants** : `ON` (pour les tests)

3. URLs :
   - **Valid redirect URIs** : `http://localhost:3000/*`, `http://frontend-service:3000/*`
   - **Web origins** : `*`

### 3. Créer des Rôles (Optionnel)

1. Allez dans **Realm roles** > **Create role**
2. Créez des rôles comme :
   - `user`
   - `admin`
   - `service-account`

3. Assignez les rôles aux utilisateurs dans **Users** > **Role mapping**

## 👤 Créer un Utilisateur de Test

1. Allez dans **Users** > **Create new user**
2. Remplissez :
   - **Username** : `testuser`
   - **Email** : `test@example.com`
   - **Email verified** : `ON`
   - **Enabled** : `ON`
   - Cliquez sur **Create**

3. Allez dans l'onglet **Credentials**
4. Définissez un mot de passe :
   - **Password** : `testpassword`
   - **Temporary** : `OFF`
   - Cliquez sur **Save**

## 🧪 Test de l'Authentification

### 1. Obtenir un Token d'Accès

#### Méthode 1 : Via curl (Client Credentials Flow pour les services)

```bash
# Obtenir le token pour un service backend
curl -X POST "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=microservices-client" \
  -d "client_secret=VOTRE_CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

#### Méthode 2 : Via curl (Password Flow pour les utilisateurs)

```bash
curl -X POST "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=frontend-client" \
  -d "username=testuser" \
  -d "password=testpassword" \
  -d "grant_type=password"
```

La réponse contiendra un `access_token` :

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "token_type": "Bearer",
  "scope": "profile email"
}
```

### 2. Tester un Endpoint Protégé

```bash
# Utiliser le token pour accéder à un service
curl -X GET "http://localhost:8083/usage/current" \
  -H "Authorization: Bearer VOTRE_ACCESS_TOKEN"
```

### 3. Tester avec Postman

1. Créez une nouvelle requête
2. Allez dans l'onglet **Authorization**
3. Sélectionnez **OAuth 2.0**
4. Configurez :
   - **Grant Type** : `Authorization Code` ou `Client Credentials`
   - **Access Token URL** : `http://localhost:8080/realms/smarthome/protocol/openid-connect/token`
   - **Client ID** : `frontend-client` ou `microservices-client`
   - **Client Secret** : (si nécessaire)
5. Cliquez sur **Get New Access Token**
6. Utilisez le token dans vos requêtes

## 🔗 Intégration avec les Services

### Vérification de la Configuration

Les services sont déjà configurés pour utiliser Keycloak. Vérifiez que :

1. **Les dépendances OAuth2** sont ajoutées dans les `pom.xml`
2. **Les classes SecurityConfig** sont créées
3. **Les fichiers application-kubernetes.properties** contiennent la configuration Keycloak
4. **Les déploiements Kubernetes** incluent les variables d'environnement Keycloak

### Reconstruire et Redéployer les Services

```bash
# Reconstruire les images Docker
cd usage-collector-service
docker build -t salmaidoufkir/usage-collector-service:latest .
docker push salmaidoufkir/usage-collector-service:latest

# Répéter pour chaque service...

# Redéployer dans Kubernetes
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
```

### Vérifier les Logs

```bash
# Vérifier que les services se connectent à Keycloak
kubectl logs -n smarthome deployment/usage-collector-service --tail=50

# Rechercher les erreurs d'authentification
kubectl logs -n smarthome deployment/usage-collector-service | grep -i "keycloak\|oauth\|jwt\|security"
```

## 🐛 Dépannage

### Problème : "Unable to verify token"

**Cause** : Le service ne peut pas contacter Keycloak ou l'URL est incorrecte.

**Solution** :
1. Vérifiez que Keycloak est accessible depuis les pods :
   ```bash
   kubectl exec -n smarthome deployment/usage-collector-service -- curl http://keycloak-service:8080/realms/smarthome/.well-known/openid-configuration
   ```

2. Vérifiez les variables d'environnement :
   ```bash
   kubectl exec -n smarthome deployment/usage-collector-service -- env | grep KEYCLOAK
   ```

3. Vérifiez le ConfigMap :
   ```bash
   kubectl get configmap services-config -n smarthome -o yaml
   ```

### Problème : "401 Unauthorized"

**Cause** : Le token est invalide, expiré, ou manquant.

**Solution** :
1. Vérifiez que le token est inclus dans le header :
   ```bash
   curl -v -H "Authorization: Bearer VOTRE_TOKEN" http://localhost:8083/usage/current
   ```

2. Vérifiez que le token n'est pas expiré

3. Obtenez un nouveau token

### Problème : Keycloak ne démarre pas

**Cause** : Problème de connexion à PostgreSQL ou ressources insuffisantes.

**Solution** :
1. Vérifiez les logs :
   ```bash
   kubectl logs -n smarthome -l app=keycloak
   ```

2. Vérifiez que PostgreSQL est accessible :
   ```bash
   kubectl exec -n smarthome deployment/keycloak -- ping postgres-service
   ```

3. Vérifiez les ressources :
   ```bash
   kubectl describe pod -n smarthome -l app=keycloak
   ```

### Problème : Les endpoints Actuator sont protégés

**Cause** : La configuration Spring Security bloque les endpoints Actuator.

**Solution** : Vérifiez que `SecurityConfig.java` permet l'accès aux endpoints `/actuator/health` et `/actuator/info`.

## 📚 Ressources Supplémentaires

- [Documentation Keycloak](https://www.keycloak.org/documentation)
- [Spring Security OAuth2 Resource Server](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/index.html)
- [Keycloak avec Kubernetes](https://www.keycloak.org/server/containers)

## ✅ Checklist de Vérification

- [ ] Keycloak déployé et accessible
- [ ] Realm `smarthome` créé
- [ ] Clients OAuth2 créés pour chaque service
- [ ] Utilisateur de test créé
- [ ] Token d'accès obtenu avec succès
- [ ] Services redéployés avec la configuration Keycloak
- [ ] Endpoints protégés testés et fonctionnels
- [ ] Logs vérifiés pour les erreurs

---

**Note** : Pour la production, assurez-vous de :
- Utiliser HTTPS
- Configurer des secrets robustes
- Limiter les durées de vie des tokens
- Implémenter la rotation des secrets
- Configurer le monitoring et les alertes


