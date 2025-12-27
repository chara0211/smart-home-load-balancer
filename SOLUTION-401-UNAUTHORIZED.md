# Solution : Erreurs 401 Unauthorized

## 🔴 Problèmes Identifiés

1. **usage-collector-service crash** : Erreur `startupState` n'existe pas
2. **Frontend n'envoie pas de token** : Les services backend nécessitent OAuth2/Keycloak mais le frontend n'envoie pas de token Bearer

## ✅ Solutions

### Solution 1 : Corriger usage-collector-service (URGENT)

Le service crash à cause de `startupState` dans la configuration. **L'image Docker doit être rebuildée** car la configuration dans le code a été corrigée mais l'image n'a pas été mise à jour.

**Option A : Rebuild l'image (Recommandé)**
```powershell
cd usage-collector-service
docker build -t salmaidoufkir/usage-collector-service:latest .
docker push salmaidoufkir/usage-collector-service:latest
kubectl rollout restart deployment/usage-collector-service -n smarthome
```

**Option B : Solution temporaire - Désactiver la validation**
Ajoutez dans `application-kubernetes.properties` :
```properties
management.endpoint.health.validate-group-membership=false
```

### Solution 2 : Ajouter l'Authentification au Frontend

Le frontend doit envoyer un token Bearer dans les headers des requêtes vers les services backend.

#### Option A : Désactiver l'authentification pour le développement (RAPIDE)

Modifiez les SecurityConfig des services pour permettre l'accès sans authentification en développement :

```java
// Dans SecurityConfig.java de chaque service
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/actuator/health/**", "/actuator/info", "/actuator/health").permitAll()
    .requestMatchers("/**").permitAll()  // TEMPORAIRE - Pour le développement
    .anyRequest().authenticated()
)
```

**⚠️ ATTENTION :** Cette solution désactive l'authentification. À utiliser uniquement pour le développement.

#### Option B : Implémenter l'authentification dans le frontend (DÉFINITIF)

1. **Installer les dépendances Keycloak** :
```bash
cd frontend
npm install @react-keycloak/web keycloak-js
```

2. **Configurer Keycloak dans le frontend** :
   - Créer un fichier de configuration Keycloak
   - Initialiser Keycloak au démarrage
   - Récupérer le token et l'ajouter aux headers

3. **Modifier les routes API** pour inclure le token :
```typescript
const token = keycloak.token;
const upstream = await fetch(`${base}/peaks/recent?limit=${limit}`, {
    headers: {
        'Authorization': `Bearer ${token}`
    },
    cache: "no-store",
    signal: controller.signal
});
```

## 🎯 Solution Rapide (Recommandée pour le développement)

### 1. Corriger usage-collector-service

```powershell
# Modifier temporairement la config pour désactiver la validation
kubectl set env deployment/usage-collector-service -n smarthome MANAGEMENT_ENDPOINT_HEALTH_VALIDATE_GROUP_MEMBERSHIP=false

# OU rebuild l'image
cd usage-collector-service
docker build -t salmaidoufkir/usage-collector-service:latest .
docker push salmaidoufkir/usage-collector-service:latest
kubectl rollout restart deployment/usage-collector-service -n smarthome
```

### 2. Désactiver l'authentification temporairement

Modifiez les SecurityConfig de tous les services pour permettre l'accès sans authentification :

```java
.requestMatchers("/**").permitAll()
```

Puis rebuild les images.

## 📋 État Actuel

- ✅ PostgreSQL : `1/1 Ready`
- ✅ RabbitMQ : `1/1 Running`
- ✅ Keycloak : `1/1 Ready`
- ✅ billing-service : `1/1 Ready`
- ✅ device-simulator-service : `1/1 Ready`
- ✅ optimizer-service : `1/1 Ready`
- ✅ peak-detector-service : `1/1 Ready`
- ❌ usage-collector-service : `CrashLoopBackOff` (à corriger)

## 🔍 Vérification

Après les corrections :

```powershell
# Vérifier les pods
kubectl get pods -n smarthome

# Vérifier les logs
kubectl logs -n smarthome usage-collector-service-<pod-name> --tail=50

# Tester un endpoint
kubectl port-forward -n smarthome <billing-pod> 8086:8086
curl http://localhost:8086/billing/savings
```

## ⚠️ Note Importante

Pour la **production**, vous devez :
1. ✅ Implémenter l'authentification complète dans le frontend
2. ✅ Rebuild toutes les images avec les SecurityConfig corrects
3. ✅ Configurer Keycloak correctement

Pour le **développement**, vous pouvez temporairement désactiver l'authentification.

