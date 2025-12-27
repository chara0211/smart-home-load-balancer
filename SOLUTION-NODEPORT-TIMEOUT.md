# Solution : NodePort ERR_CONNECTION_TIMED_OUT

## 🔴 Problème

Erreur `ERR_CONNECTION_TIMED_OUT` lors de l'accès à `http://192.168.49.2:30000`

## ✅ Causes Possibles

1. **Firewall Windows** bloque le port 30000
2. **Minikube** n'expose pas correctement le NodePort
3. **Réseau Minikube** non accessible depuis la machine hôte

## ✅ Solutions

### Solution 1 : Utiliser Port-Forward (Recommandé)

Le port-forward est plus fiable que le NodePort pour le développement local :

```powershell
# Démarrer le port-forward
kubectl port-forward -n smarthome svc/frontend-service-nodeport 3000:3000
```

Puis accéder à : **http://localhost:3000**

**Avantages** :
- ✅ Fonctionne toujours
- ✅ Pas de problème de firewall
- ✅ URL fixe (localhost:3000)

### Solution 2 : Vérifier le Firewall Windows

```powershell
# Vérifier si le port est bloqué
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*30000*"}

# Autoriser le port (si nécessaire)
New-NetFirewallRule -DisplayName "Minikube NodePort 30000" -Direction Inbound -LocalPort 30000 -Protocol TCP -Action Allow
```

### Solution 3 : Utiliser minikube tunnel (Alternative)

```powershell
# Dans un terminal séparé
minikube tunnel
```

Cela expose les services NodePort sur localhost.

### Solution 4 : Vérifier la Configuration Minikube

```powershell
# Vérifier que Minikube est en cours d'exécution
minikube status

# Vérifier l'IP de Minikube
minikube ip

# Vérifier les services exposés
minikube service list -n smarthome
```

## 🧪 Test Rapide

### Test 1 : Port-Forward

```powershell
# Terminal 1
kubectl port-forward -n smarthome svc/frontend-service-nodeport 3000:3000

# Terminal 2 ou navigateur
# Ouvrir http://localhost:3000
```

### Test 2 : Vérifier la Connexion

```powershell
# Tester la connexion au NodePort
Test-NetConnection -ComputerName 192.168.49.2 -Port 30000
```

Si cela échoue, le firewall bloque probablement le port.

## 📝 Configuration Keycloak avec Port-Forward

Si vous utilisez le port-forward (`localhost:3000`), configurez Keycloak avec :

- **Valid redirect URIs** : `http://localhost:3000/*`
- **Web origins** : `http://localhost:3000`

## 🎯 Recommandation

**Pour le développement local**, utilisez **port-forward** au lieu de NodePort :

```powershell
# Script pour démarrer le port-forward
kubectl port-forward -n smarthome svc/frontend-service-nodeport 3000:3000
```

C'est plus fiable et évite les problèmes de firewall.

