# Guide : Accès au Frontend

## 🌐 Deux Méthodes d'Accès

### Méthode 1 : Via Minikube Service (Port-Forward Automatique)

```powershell
minikube service frontend-service-nodeport -n smarthome
```

**Résultat** : Ouvre automatiquement `http://127.0.0.1:XXXXX` (port aléatoire)

**Avantages** :
- ✅ Port-forward automatique
- ✅ Fonctionne même si le NodePort n'est pas accessible directement
- ✅ Plus simple à utiliser

**Inconvénients** :
- ⚠️ Port change à chaque fois
- ⚠️ URL différente de celle configurée dans Keycloak

### Méthode 2 : Accès Direct via NodePort (Recommandé)

**URL** : `http://192.168.49.2:30000`

**Avantages** :
- ✅ URL fixe (utile pour configurer Keycloak)
- ✅ Accès direct sans port-forward
- ✅ Plus proche de la configuration de production

**Inconvénients** :
- ⚠️ Nécessite que le NodePort soit accessible depuis votre machine
- ⚠️ Peut ne pas fonctionner si Minikube n'est pas accessible directement

## 🔧 Configuration Keycloak

Pour que l'authentification fonctionne correctement, vous devez utiliser **l'URL NodePort** dans Keycloak :

1. **Valid redirect URIs** : `http://192.168.49.2:30000/*`
2. **Web origins** : `http://192.168.49.2:30000`

## 🧪 Tester les Deux Méthodes

### Test 1 : Via Minikube Service

```powershell
minikube service frontend-service-nodeport -n smarthome
```

Cela ouvrira `http://127.0.0.1:51357` (ou un autre port).

### Test 2 : Accès Direct

Ouvrez manuellement dans le navigateur : `http://192.168.49.2:30000`

## ⚠️ Problème avec Minikube Service

Si vous utilisez `minikube service` mais que vous avez configuré Keycloak avec l'URL NodePort (`192.168.49.2:30000`), l'authentification peut échouer car :

- Le frontend est accessible sur `127.0.0.1:51357`
- Keycloak attend les redirections depuis `192.168.49.2:30000`

## ✅ Solution Recommandée

**Utilisez toujours l'URL NodePort directe** pour la cohérence :

```powershell
# Obtenir l'URL
$minikubeIp = minikube ip
$nodePort = kubectl get svc -n smarthome frontend-service-nodeport -o jsonpath='{.spec.ports[0].nodePort}'
$url = "http://$minikubeIp:$nodePort"
Write-Host "Frontend: $url" -ForegroundColor Green

# Ouvrir dans le navigateur
Start-Process $url
```

Ou créez un script :

```powershell
# scripts/ouvrir-frontend.ps1
$minikubeIp = minikube ip
Start-Process "http://$minikubeIp:30000"
```

## 🔍 Vérification

Pour vérifier que le NodePort fonctionne :

```powershell
# Tester la connexion
$minikubeIp = minikube ip
Invoke-WebRequest -Uri "http://$minikubeIp:30000" -UseBasicParsing
```

Si cela fonctionne, vous pouvez utiliser cette URL directement.

## 📝 Note

- `minikube service` est pratique pour le développement rapide
- L'URL NodePort directe est meilleure pour la configuration Keycloak
- Les deux méthodes fonctionnent, mais utilisez la même partout pour éviter les problèmes CORS

