# Guide de Test avec NodePort

## 🌐 URLs des Services

### Frontend (NodePort)
Le frontend est accessible via :
- **URL** : `http://<minikube-ip>:30000`
- Ou utilisez : `minikube service frontend-service-nodeport -n smarthome`

### Keycloak (NodePort)
Keycloak est accessible via :
- **URL** : `http://<minikube-ip>:30080`
- Ou utilisez : `minikube service keycloak-service -n smarthome`

## 🔧 Configuration Keycloak avec NodePort

### Étape 1 : Accéder à Keycloak

```powershell
# Obtenir l'URL de Keycloak
minikube service keycloak-service -n smarthome --url
```

Ou directement :
```powershell
minikube service keycloak-service -n smarthome
```

### Étape 2 : Configurer le Client Frontend

1. **Ouvrir Keycloak** (via l'URL NodePort)
2. **Se connecter** avec les credentials admin
3. **Aller dans "Clients"** > Sélectionner ou créer `frontend-client`
4. **Configurer les URLs** :
   - **Valid redirect URIs** : 
     - `http://<minikube-ip>:30000/*`
     - `http://localhost:30000/*` (pour le développement local)
   - **Web origins** : 
     - `http://<minikube-ip>:30000`
     - `http://localhost:30000`
   - **Cliquer sur "Save"**

### Étape 3 : Créer un Utilisateur

1. Aller dans "Users" > "Create new user"
2. Username : `testuser`
3. Aller dans "Credentials" > Définir le mot de passe : `testpass`
4. Désactiver "Temporary"
5. Cliquer sur "Set password"

## 🧪 Test du Frontend

### Option A : Via Minikube Service

```powershell
minikube service frontend-service-nodeport -n smarthome
```

Cela ouvrira automatiquement le navigateur avec l'URL correcte.

### Option B : URL Directe

```powershell
# Obtenir l'IP de Minikube
$minikubeIp = minikube ip
Write-Host "Frontend: http://$minikubeIp:30000" -ForegroundColor Green
Write-Host "Keycloak: http://$minikubeIp:30080" -ForegroundColor Green
```

Puis ouvrir manuellement dans le navigateur.

## ⚙️ Configuration des Variables d'Environnement

Si le frontend doit se connecter à Keycloak depuis le navigateur, il doit utiliser l'URL NodePort de Keycloak.

### Mettre à jour le Frontend

Modifiez `k8s/services/frontend/deployment.yaml` pour ajouter :

```yaml
env:
  - name: NEXT_PUBLIC_KEYCLOAK_URL
    value: "http://<minikube-ip>:30080"  # URL NodePort de Keycloak
  - name: KEYCLOAK_URL
    value: "http://keycloak-service:8080"  # URL interne pour les routes API
```

Ou utilisez une variable dynamique :

```yaml
env:
  - name: NEXT_PUBLIC_KEYCLOAK_URL
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
    # Puis construire l'URL dans le code
```

## 🔍 Vérification

### 1. Vérifier que les Services sont Accessibles

```powershell
# Frontend
$minikubeIp = minikube ip
Invoke-WebRequest -Uri "http://$minikubeIp:30000" -UseBasicParsing

# Keycloak
Invoke-WebRequest -Uri "http://$minikubeIp:30080" -UseBasicParsing
```

### 2. Tester l'Authentification

1. Ouvrir le frontend via NodePort
2. Se connecter avec `testuser` / `testpass`
3. Vérifier que le dashboard s'affiche
4. Vérifier dans la console (F12) qu'il n'y a plus d'erreurs 401

## 🐛 Problèmes Courants

### Le Frontend ne peut pas se connecter à Keycloak

**Problème** : Le frontend (côté navigateur) essaie de se connecter à `keycloak-service:8080` qui n'est pas accessible depuis le navigateur.

**Solution** : Utiliser l'URL NodePort de Keycloak dans les variables d'environnement du frontend.

### CORS Errors

**Problème** : Erreurs CORS lors de la connexion à Keycloak.

**Solution** : S'assurer que "Web origins" dans Keycloak inclut l'URL NodePort du frontend.

### Le Token n'est pas envoyé

**Problème** : Le token n'est pas sauvegardé ou envoyé correctement.

**Solution** : 
1. Vérifier dans la console (F12 > Application > Local Storage) que `auth_token` existe
2. Vérifier dans Network que les requêtes incluent `Authorization: Bearer ...`

## 📝 Notes Importantes

- **Pour le navigateur** : Utilisez les URLs NodePort (accessibles depuis votre machine)
- **Pour les services backend** : Utilisez les noms de service Kubernetes (ex: `keycloak-service:8080`)
- **Les routes API Next.js** : Peuvent utiliser l'URL interne `keycloak-service:8080` car elles s'exécutent côté serveur

## 🚀 Script Rapide

```powershell
# Obtenir les URLs
$minikubeIp = minikube ip
$frontendUrl = "http://$minikubeIp:30000"
$keycloakUrl = "http://$minikubeIp:30080"

Write-Host "Frontend: $frontendUrl" -ForegroundColor Green
Write-Host "Keycloak: $keycloakUrl" -ForegroundColor Green

# Ouvrir dans le navigateur
Start-Process $frontendUrl
Start-Process $keycloakUrl
```

