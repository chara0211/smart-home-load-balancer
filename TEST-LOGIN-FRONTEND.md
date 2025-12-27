# Test du Login Frontend

## ✅ Modifications Appliquées

Le LoginForm est maintenant intégré dans la page principale :
- ✅ La page vérifie automatiquement si l'utilisateur est authentifié
- ✅ Si non authentifié, le LoginForm s'affiche
- ✅ Si authentifié, le dashboard s'affiche
- ✅ Le token est vérifié pour l'expiration

## 🧪 Comment Tester

### 1. Accéder au Frontend

```powershell
minikube service frontend-service-nodeport -n smarthome
```

Ou ouvrir directement : `http://192.168.49.2:30000`

### 2. Vérifier que le LoginForm s'Affiche

Quand vous ouvrez le frontend, vous devriez voir :
- ✅ Un formulaire de login centré
- ✅ Deux champs : Username et Password
- ✅ Un bouton "Login"

### 3. Configurer Keycloak (si pas déjà fait)

1. **Accéder à Keycloak** :
```powershell
minikube service keycloak-service -n smarthome
```

2. **Créer le client** `frontend-client` :
   - Valid redirect URIs : `http://192.168.49.2:30000/*`
   - Web origins : `http://192.168.49.2:30000`

3. **Créer un utilisateur** :
   - Username : `testuser`
   - Password : `testpass`

### 4. Tester le Login

1. **Dans le formulaire de login** :
   - Username : `testuser`
   - Password : `testpass`
   - Cliquer sur "Login"

2. **Résultat attendu** :
   - ✅ Le formulaire disparaît
   - ✅ Le dashboard s'affiche
   - ✅ Pas d'erreurs dans la console (F12)

### 5. Vérifier l'Authentification

1. **Ouvrir la console du navigateur** (F12)
2. **Aller dans "Application" > "Local Storage"**
3. **Vérifier** qu'il y a une clé `auth_token` avec une valeur

4. **Aller dans "Network"**
5. **Vérifier** que les requêtes incluent `Authorization: Bearer ...` dans les headers

## 🐛 Dépannage

### Le LoginForm ne s'affiche pas

**Vérifier** :
```powershell
# Vérifier les logs du frontend
kubectl logs -n smarthome -l app=frontend --tail=50
```

**Solution** : Rebuild le frontend si nécessaire

### Erreur lors du login

**Vérifier** :
1. Keycloak est accessible
2. Le client `frontend-client` existe
3. L'utilisateur existe avec le bon mot de passe
4. Les URLs dans Keycloak sont correctes

**Vérifier les logs** :
```powershell
# Logs du frontend
kubectl logs -n smarthome -l app=frontend --tail=50

# Logs de Keycloak
kubectl logs -n smarthome -l app=keycloak --tail=50
```

### Le dashboard s'affiche mais avec des erreurs 401

**Cause** : Le token n'est pas envoyé avec les requêtes

**Vérifier** :
1. Le token existe dans localStorage
2. Le token est envoyé dans les headers (Network tab)
3. Le token n'est pas expiré

**Solution** : Se reconnecter

### Le token expire rapidement

**Solution** : Augmenter la durée de vie du token dans Keycloak :
1. Aller dans "Clients" > `frontend-client`
2. Aller dans "Advanced settings"
3. Augmenter "Access Token Lifespan"

## 📝 Notes

- Le token est stocké dans `localStorage`
- Le token est vérifié pour l'expiration au chargement
- Si le token est expiré, l'utilisateur est déconnecté automatiquement
- Pour se déconnecter, supprimer `auth_token` de localStorage

## 🔄 Rebuild si Nécessaire

Si vous avez modifié le code, rebuild le frontend :

```powershell
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest
kubectl rollout restart deployment/frontend -n smarthome
```

