# Solution : Erreur lors du Login

## 🔴 Problème

Erreur "Application error: a client-side exception has occurred" lors du remplissage du formulaire d'authentification.

## ✅ Corrections Appliquées

### 1. Amélioration de la Gestion d'Erreurs

- ✅ Meilleure gestion des erreurs de réponse HTTP
- ✅ Vérification que le token existe avant de le sauvegarder
- ✅ Vérification que `window` existe avant d'utiliser localStorage
- ✅ Logs d'erreur dans la console pour le débogage

### 2. Vérifications Ajoutées

- Vérification que `data.access_token` existe
- Vérification que `window` est disponible (côté client)
- Meilleure extraction des messages d'erreur

## 🧪 Tests à Effectuer

### 1. Vérifier les Logs du Frontend

```powershell
kubectl logs -n smarthome -l app=frontend --tail=100
```

Cherchez les erreurs liées à :
- `/api/auth/login`
- Keycloak
- Authentication

### 2. Vérifier la Console du Navigateur

1. Ouvrir le frontend
2. Ouvrir la console (F12)
3. Essayer de se connecter
4. Vérifier les erreurs dans la console

### 3. Vérifier que Keycloak est Accessible

```powershell
# Depuis le pod frontend
kubectl exec -n smarthome <frontend-pod-name> -- wget -qO- http://keycloak-service:8080/health/ready
```

### 4. Tester l'API de Login Directement

```powershell
# Port-forward vers le frontend
kubectl port-forward -n smarthome deployment/frontend 3000:3000

# Dans un autre terminal, tester l'API
Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login?username=testuser&password=testpass"
```

## 🐛 Causes Possibles

### 1. Keycloak n'est pas accessible depuis le Frontend

**Vérifier** :
- Le service Keycloak est prêt : `kubectl get pods -n smarthome -l app=keycloak`
- Le service existe : `kubectl get svc -n smarthome keycloak-service`
- Les variables d'environnement : `kubectl describe deployment frontend -n smarthome | Select-String "KEYCLOAK"`

### 2. Le Client Keycloak n'existe pas

**Vérifier** :
- Accéder à Keycloak : `minikube service keycloak-service -n smarthome`
- Vérifier que le client `frontend-client` existe
- Vérifier les URLs de redirection

### 3. L'Utilisateur n'existe pas

**Vérifier** :
- L'utilisateur existe dans Keycloak
- Le mot de passe est correct
- L'utilisateur n'est pas désactivé

### 4. Erreur CORS

**Vérifier** :
- Les "Web origins" dans Keycloak incluent l'URL du frontend
- Les "Valid redirect URIs" incluent l'URL du frontend

## 📝 Prochaines Étapes

1. **Rebuild le frontend** avec les corrections :
```powershell
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest
kubectl rollout restart deployment/frontend -n smarthome
```

2. **Vérifier les logs** après le redéploiement

3. **Tester à nouveau** le login

4. **Vérifier la console du navigateur** pour plus de détails sur l'erreur

## 🔍 Debug Avancé

### Activer les Logs Détaillés

Dans `frontend/app/components/LoginForm.tsx`, ajoutez des logs :

```typescript
console.log('Attempting login for:', username);
console.log('Response status:', response.status);
console.log('Response data:', data);
```

### Vérifier la Réponse de l'API

Modifiez temporairement le code pour afficher la réponse complète :

```typescript
const response = await fetch(...);
console.log('Full response:', response);
const text = await response.text();
console.log('Response text:', text);
```

