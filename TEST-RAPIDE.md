# Test Rapide : Authentification

## 🚀 Démarrage Rapide (2 minutes)

### Option A : Script Automatique

```powershell
.\scripts\demarrer-tests.ps1
```

Ce script va :
- ✅ Vérifier que les services sont prêts
- ✅ Démarrer les port-forwards automatiquement
- ✅ Ouvrir Keycloak sur http://localhost:8080
- ✅ Ouvrir Frontend sur http://localhost:3000

### Option B : Manuel

#### 1. Démarrer les Port-Forwards

**Terminal 1 - Keycloak :**
```powershell
kubectl port-forward -n smarthome svc/keycloak-service 8080:8080
```

**Terminal 2 - Frontend :**
```powershell
kubectl port-forward -n smarthome svc/frontend-service 3000:3000
```

#### 2. Configurer Keycloak (5 minutes)

1. **Ouvrir Keycloak** : http://localhost:8080
2. **Se connecter** : 
   - Cliquer sur "Administration Console"
   - Utiliser les credentials du secret `keycloak-secret`
3. **Créer le Client** :
   - Aller dans "Clients" > "Create client"
   - Client ID : `frontend-client`
   - Client authentication : **Désactivé** (public)
   - Valid redirect URIs : `http://localhost:3000/*`
   - Web origins : `http://localhost:3000`
   - Sauvegarder
4. **Créer un Utilisateur** :
   - Aller dans "Users" > "Create new user"
   - Username : `testuser`
   - Aller dans "Credentials" > Définir le mot de passe : `testpass`
   - Désactiver "Temporary"

#### 3. Tester le Frontend

1. **Ouvrir** : http://localhost:3000
2. **Se connecter** avec :
   - Username : `testuser`
   - Password : `testpass`
3. **Vérifier** :
   - Le dashboard s'affiche
   - Pas d'erreurs 401 dans la console (F12)

## 🧪 Test avec PowerShell

### Obtenir un Token

```powershell
# Obtenir un token depuis Keycloak
$body = @{
    grant_type = "password"
    client_id = "frontend-client"
    username = "testuser"
    password = "testpass"
}

$response = Invoke-RestMethod -Uri "http://localhost:8080/realms/smarthome/protocol/openid-connect/token" `
    -Method Post `
    -Body ($body | ConvertTo-Json) `
    -ContentType "application/json"

$token = $response.access_token
Write-Host "Token : $($token.Substring(0, 50))..." -ForegroundColor Green
```

### Tester un Endpoint Backend

```powershell
# Port-forward vers billing-service
kubectl port-forward -n smarthome deployment/billing-service 8086:8086

# Dans un autre terminal, tester avec le token
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:8086/billing/savings" -Headers $headers
```

### Tester une Route API Next.js

```powershell
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-RestMethod -Uri "http://localhost:3000/api/billing/savings" -Headers $headers
```

## ✅ Checklist

- [ ] Keycloak accessible sur http://localhost:8080
- [ ] Client `frontend-client` créé dans Keycloak
- [ ] Utilisateur `testuser` créé avec mot de passe
- [ ] Frontend accessible sur http://localhost:3000
- [ ] Login fonctionne
- [ ] Dashboard s'affiche
- [ ] Pas d'erreurs 401 dans la console

## 🐛 Problèmes Courants

### Keycloak n'est pas accessible

```powershell
# Vérifier les pods
kubectl get pods -n smarthome -l app=keycloak

# Vérifier les logs
kubectl logs -n smarthome -l app=keycloak --tail=50
```

### Erreur 401 persiste

1. Vérifier que le token est dans localStorage (F12 > Application > Local Storage)
2. Vérifier que le token est envoyé dans les headers (F12 > Network)
3. Vérifier que le token n'est pas expiré (se reconnecter)

### Le frontend ne se connecte pas

1. Vérifier que Keycloak est accessible depuis le frontend
2. Vérifier les variables d'environnement :
```powershell
kubectl describe deployment frontend -n smarthome | Select-String "KEYCLOAK"
```

## 📝 Notes

- Les port-forwards doivent rester ouverts pendant les tests
- Pour arrêter : `Ctrl+C` dans les terminaux ou fermer les fenêtres PowerShell
- Le token est valide pendant ~5 minutes (configurable dans Keycloak)

