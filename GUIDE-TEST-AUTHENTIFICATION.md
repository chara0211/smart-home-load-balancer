# Guide de Test : Authentification Keycloak

## 🚀 Démarrage Rapide

### 1. Vérifier l'État des Services

```powershell
kubectl get pods -n smarthome
```

Tous les services doivent être `1/1 Ready` :
- ✅ keycloak
- ✅ frontend
- ✅ billing-service
- ✅ usage-collector-service
- ✅ device-simulator-service
- ✅ peak-detector-service
- ✅ optimizer-service

### 2. Accéder aux Services

#### A. Keycloak

```powershell
# Dans un terminal
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
```

Puis ouvrir : **http://localhost:8080**

#### B. Frontend

```powershell
# Dans un autre terminal
kubectl port-forward -n smarthome deployment/frontend 3000:3000
```

Puis ouvrir : **http://localhost:3000**

## 🔧 Configuration Keycloak

### Étape 1 : Se Connecter à Keycloak

1. Ouvrir http://localhost:8080
2. Cliquer sur "Administration Console"
3. Se connecter avec les credentials admin (définis dans le secret `keycloak-secret`)

### Étape 2 : Créer/Configurer le Realm

1. Si le realm "smarthome" n'existe pas :
   - Cliquer sur le dropdown en haut à gauche
   - Cliquer sur "Create Realm"
   - Nom : `smarthome`
   - Cliquer sur "Create"

2. Si le realm existe déjà, le sélectionner

### Étape 3 : Créer le Client Frontend

1. Aller dans "Clients" (menu de gauche)
2. Cliquer sur "Create client"
3. Remplir :
   - **Client ID** : `frontend-client`
   - **Client authentication** : Désactivé (public client)
   - Cliquer sur "Next"
4. Dans "Capability config" :
   - ✅ Standard flow
   - ✅ Direct access grants
   - Cliquer sur "Next"
5. Dans "Login settings" :
   - **Valid redirect URIs** : `http://localhost:3000/*`
   - **Web origins** : `http://localhost:3000`
   - Cliquer sur "Save"

### Étape 4 : Créer un Utilisateur de Test

1. Aller dans "Users" (menu de gauche)
2. Cliquer sur "Create new user"
3. Remplir :
   - **Username** : `testuser` (ou autre)
   - **Email** : `test@example.com` (optionnel)
   - Cliquer sur "Create"
4. Aller dans l'onglet "Credentials"
5. Définir un mot de passe :
   - **Password** : `testpass` (ou autre)
   - **Password confirmation** : `testpass`
   - Désactiver "Temporary" (pour que le mot de passe ne soit pas temporaire)
   - Cliquer sur "Set password"

## 🧪 Tests

### Test 1 : Test de Login via l'Interface Web

1. Ouvrir http://localhost:3000
2. Si la page de login s'affiche, utiliser les credentials :
   - Username : `testuser`
   - Password : `testpass`
3. Vérifier que le dashboard s'affiche
4. Vérifier dans la console du navigateur (F12) qu'il n'y a plus d'erreurs 401

### Test 2 : Test avec curl (PowerShell)

```powershell
# 1. Obtenir un token
$body = @{
    grant_type = "password"
    client_id = "frontend-client"
    username = "testuser"
    password = "testpass"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

$token = $response.access_token
Write-Host "Token obtenu : $($token.Substring(0, 50))..." -ForegroundColor Green

# 2. Tester un endpoint backend
kubectl port-forward -n smarthome deployment/billing-service 8086:8086

# Dans un autre terminal
$headers = @{
    Authorization = "Bearer $token"
}

$result = Invoke-RestMethod -Uri "http://localhost:8086/billing/savings" -Headers $headers
Write-Host "Résultat :" -ForegroundColor Green
$result | ConvertTo-Json
```

### Test 3 : Test Direct des Routes API Next.js

```powershell
# 1. Obtenir un token (comme ci-dessus)
$token = "..."

# 2. Tester une route API Next.js
$headers = @{
    Authorization = "Bearer $token"
}

$result = Invoke-RestMethod -Uri "http://localhost:3000/api/billing/savings" -Headers $headers
Write-Host "Résultat :" -ForegroundColor Green
$result | ConvertTo-Json
```

### Test 4 : Vérifier les Logs

```powershell
# Logs du frontend
kubectl logs -n smarthome -l app=frontend --tail=50

# Logs d'un service backend
kubectl logs -n smarthome deployment/billing-service --tail=50
```

## ✅ Checklist de Vérification

- [ ] Keycloak est accessible sur http://localhost:8080
- [ ] Le realm "smarthome" existe
- [ ] Le client "frontend-client" est créé et configuré
- [ ] Un utilisateur de test existe avec un mot de passe
- [ ] Le frontend est accessible sur http://localhost:3000
- [ ] La page de login s'affiche
- [ ] Le login fonctionne avec les credentials Keycloak
- [ ] Le dashboard s'affiche après le login
- [ ] Les erreurs 401 ont disparu dans la console du navigateur
- [ ] Les données s'affichent correctement dans le dashboard

## 🐛 Dépannage

### Problème : Keycloak n'est pas accessible

```powershell
# Vérifier que Keycloak est prêt
kubectl get pods -n smarthome -l app=keycloak

# Vérifier les logs
kubectl logs -n smarthome -l app=keycloak --tail=50

# Vérifier le service
kubectl get svc -n smarthome keycloak-service
```

### Problème : Erreur 401 persiste

1. Vérifier que le token est bien sauvegardé dans localStorage :
   - Ouvrir la console du navigateur (F12)
   - Aller dans "Application" > "Local Storage"
   - Vérifier qu'il y a une clé `auth_token`

2. Vérifier que le token est envoyé dans les headers :
   - Ouvrir "Network" dans la console
   - Vérifier qu'une requête contient `Authorization: Bearer ...`

3. Vérifier que le token est valide :
   - Le token peut être expiré, se reconnecter

### Problème : Le frontend ne se connecte pas à Keycloak

1. Vérifier les variables d'environnement :
```powershell
kubectl describe deployment frontend -n smarthome | Select-String "KEYCLOAK"
```

2. Vérifier que Keycloak est accessible depuis le frontend :
   - Les services dans Kubernetes peuvent se connecter via `keycloak-service:8080`
   - Pour le développement local, utiliser `localhost:8080`

## 📝 Notes

- **Pour le développement local** : Utilisez `localhost:8080` pour Keycloak
- **Pour Kubernetes** : Les services utilisent `keycloak-service:8080`
- **Le token est stocké dans localStorage** : Pour la production, considérez utiliser des cookies httpOnly

