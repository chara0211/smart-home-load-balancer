# Guide : Implémentation Authentification Frontend

## ✅ Modifications Appliquées

### 1. Routes API Backend Modifiées

Toutes les routes API Next.js ont été modifiées pour :
- ✅ Récupérer le token depuis les headers de la requête
- ✅ Ajouter le token Bearer aux requêtes vers les services backend

**Fichiers modifiés :**
- `frontend/app/api/peaks/recent/route.ts`
- `frontend/app/api/devices/route.ts`
- `frontend/app/api/billing/savings/route.ts`
- `frontend/app/api/billing/current-month/route.ts`
- `frontend/app/api/billing/daily-cost/route.ts`
- `frontend/app/api/optimizer/logs/route.ts`
- `frontend/app/api/usage/current/route.ts`

### 2. Fonction safeJson Modifiée

La fonction `safeJson` dans `frontend/app/page.tsx` a été modifiée pour :
- ✅ Récupérer le token depuis localStorage
- ✅ Ajouter le token dans les headers des requêtes vers les routes API Next.js

### 3. Utilitaires d'Authentification Créés

**`frontend/lib/auth.ts`** :
- Fonctions pour récupérer le token (server-side et client-side)
- Fonction pour créer les headers avec authentification

**`frontend/lib/keycloak.ts`** :
- Configuration Keycloak
- Fonctions pour gérer le token côté client

### 4. Route API de Login Créée

**`frontend/app/api/auth/login/route.ts`** :
- Route pour se connecter à Keycloak
- Retourne le token au client

### 5. Composant de Login Créé

**`frontend/app/components/LoginForm.tsx`** :
- Composant React pour l'authentification
- Gère le login et sauvegarde le token dans localStorage

## 📋 Prochaines Étapes

### 1. Ajouter la Page de Login

Modifiez `frontend/app/page.tsx` pour :
- Vérifier si l'utilisateur est authentifié
- Afficher le LoginForm si non authentifié
- Afficher le dashboard si authentifié

**Exemple :**

```typescript
'use client';

import { useEffect, useState } from 'react';
import LoginForm from './components/LoginForm';
import AdvancedDashboard from './page-content'; // Renommez le composant actuel

export default function Page() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Vérifier si un token existe
    const token = localStorage.getItem('auth_token');
    if (token) {
      // Optionnel : Vérifier si le token est valide
      setIsAuthenticated(true);
    }
    setLoading(false);
  }, []);

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return <LoginForm onLogin={() => setIsAuthenticated(true)} />;
  }

  return <AdvancedDashboard />;
}
```

### 2. Configurer Keycloak

1. **Accéder à Keycloak** :
```powershell
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
# Puis ouvrir http://localhost:8080
```

2. **Créer un Client** :
   - Client ID: `frontend-client`
   - Access Type: `public` (ou `confidential` si vous utilisez un secret)
   - Valid Redirect URIs: `http://localhost:3000/*`
   - Web Origins: `http://localhost:3000`

3. **Créer un Utilisateur de Test** :
   - Aller dans "Users"
   - Créer un nouvel utilisateur
   - Définir un mot de passe dans l'onglet "Credentials"

### 3. Variables d'Environnement

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
        key: client-secret  # Si vous utilisez un client confidential
```

### 4. Rebuild et Redéployer

```powershell
# Rebuild le frontend
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest

# Redémarrer le déploiement
kubectl rollout restart deployment/frontend -n smarthome
```

## 🔍 Vérification

1. **Tester l'authentification** :
   - Accéder au frontend
   - Se connecter avec les credentials Keycloak
   - Vérifier que les erreurs 401 disparaissent

2. **Vérifier les logs** :
```powershell
kubectl logs -n smarthome -l app=frontend --tail=50
```

## ⚠️ Notes Importantes

1. **Pour le développement local** : Utilisez `http://localhost:8080` pour Keycloak
2. **Pour Kubernetes** : Utilisez `http://keycloak-service:8080` pour les services backend
3. **Le token est stocké dans localStorage** : Pour la production, considérez utiliser des cookies httpOnly pour plus de sécurité

## 🎯 Résultat Attendu

Après l'implémentation complète :
- ✅ Le frontend affiche une page de login
- ✅ L'utilisateur se connecte avec Keycloak
- ✅ Le token est sauvegardé et envoyé avec toutes les requêtes
- ✅ Les erreurs 401 disparaissent
- ✅ Tous les services backend sont accessibles

