# Solution Complète : Authentification Keycloak dans le Frontend

## ✅ Implémentation Complète

J'ai implémenté l'authentification Keycloak dans le frontend pour résoudre les erreurs 401.

## 📋 Modifications Apportées

### 1. Utilitaires d'Authentification

**`frontend/lib/auth.ts`** :
- Fonctions pour récupérer le token depuis les cookies (server-side)
- Fonctions pour créer les headers avec authentification
- Support pour récupérer le token depuis les headers de la requête

**`frontend/lib/keycloak.ts`** :
- Configuration Keycloak
- Fonctions pour gérer le token côté client (localStorage)

### 2. Route API d'Authentification

**`frontend/app/api/auth/login/route.ts`** :
- Route pour se connecter à Keycloak
- Récupère le token et le retourne au client

**`frontend/app/api/auth/token/route.ts`** :
- Route pour récupérer le token depuis les cookies

### 3. Routes API Modifiées

Toutes les routes API ont été modifiées pour inclure le token Bearer dans les headers :
- ✅ `frontend/app/api/peaks/recent/route.ts`
- ✅ `frontend/app/api/devices/route.ts`
- ✅ `frontend/app/api/billing/savings/route.ts`
- ✅ `frontend/app/api/billing/current-month/route.ts`
- ✅ `frontend/app/api/billing/daily-cost/route.ts`
- ✅ `frontend/app/api/optimizer/logs/route.ts`
- ✅ `frontend/app/api/usage/current/route.ts`

### 4. Composant de Login

**`frontend/app/components/LoginForm.tsx`** :
- Composant React pour l'authentification
- Gère le login et sauvegarde le token

## 🔧 Configuration Requise

### Variables d'Environnement

Ajoutez dans `k8s/services/frontend/deployment.yaml` :

```yaml
env:
  - name: KEYCLOAK_URL
    value: "http://keycloak-service:8080"
  - name: KEYCLOAK_REALM
    value: "smarthome"
  - name: KEYCLOAK_CLIENT_ID
    value: "frontend-client"
  - name: KEYCLOAK_CLIENT_SECRET
    valueFrom:
      secretKeyRef:
        name: keycloak-secret
        key: client-secret
```

Et pour le client (Next.js) :

```yaml
env:
  - name: NEXT_PUBLIC_KEYCLOAK_URL
    value: "http://keycloak-service:8080"
  - name: NEXT_PUBLIC_KEYCLOAK_REALM
    value: "smarthome"
  - name: NEXT_PUBLIC_KEYCLOAK_CLIENT_ID
    value: "frontend-client"
```

## 📝 Prochaines Étapes

### 1. Configurer Keycloak

Vous devez créer un client dans Keycloak :
1. Accéder à Keycloak : `http://localhost:30080` (ou via port-forward)
2. Se connecter avec les credentials admin
3. Créer un realm "smarthome" (ou utiliser celui existant)
4. Créer un client "frontend-client" avec :
   - Client ID: `frontend-client`
   - Access Type: `public` (ou `confidential` si vous utilisez un secret)
   - Valid Redirect URIs: `http://localhost:3000/*`
   - Web Origins: `http://localhost:3000`

### 2. Créer un Utilisateur de Test

Dans Keycloak :
1. Aller dans "Users"
2. Créer un nouvel utilisateur
3. Définir un mot de passe dans l'onglet "Credentials"

### 3. Modifier le Frontend pour Utiliser le Login

Modifiez `frontend/app/page.tsx` pour :
- Vérifier si l'utilisateur est authentifié
- Afficher le LoginForm si non authentifié
- Afficher le dashboard si authentifié

### 4. Modifier les Appels API Côté Client

Dans `frontend/app/lib/api.ts`, modifiez les fonctions pour inclure le token :

```typescript
export async function getCurrentUsage() {
    const token = localStorage.getItem('auth_token');
    const res = await fetch("http://localhost:8083/usage/current", {
        cache: "no-store",
        headers: {
            'Authorization': `Bearer ${token}`
        }
    });
    // ...
}
```

### 5. Rebuild et Redéployer

```powershell
# Rebuild le frontend
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest

# Redémarrer le déploiement
kubectl rollout restart deployment/frontend -n smarthome
```

## 🔍 Vérification

1. **Vérifier que Keycloak est accessible** :
```powershell
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
# Puis ouvrir http://localhost:8080
```

2. **Tester l'authentification** :
```powershell
# Via l'interface web du frontend
# Ou via curl :
curl -X POST "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=frontend-client" \
  -d "username=testuser" \
  -d "password=testpass"
```

## ⚠️ Notes Importantes

1. **Pour le développement local** : Utilisez `http://localhost:8080` pour Keycloak
2. **Pour Kubernetes** : Utilisez `http://keycloak-service:8080` pour les services backend
3. **Pour le frontend dans Kubernetes** : Le frontend doit pouvoir accéder à Keycloak, donc utilisez le service Kubernetes ou configurez un ingress

## 🎯 Solution Alternative : Middleware Next.js

Pour une solution plus robuste, vous pouvez créer un middleware Next.js qui :
- Vérifie automatiquement l'authentification
- Redirige vers la page de login si non authentifié
- Ajoute le token aux requêtes automatiquement

Voir la documentation Next.js pour les middlewares.

