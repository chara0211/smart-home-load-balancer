# Solution : Accès au Frontend

## 🔴 Problème

`ERR_CONNECTION_TIMED_OUT` sur `http://192.168.49.2:30000`

**Cause** : Le NodePort n'est pas accessible depuis votre machine (probablement bloqué par le firewall Windows).

## ✅ Solution : Utiliser Port-Forward (Recommandé)

Le port-forward est plus fiable que le NodePort pour le développement local.

### Option 1 : Script Automatique

```powershell
.\scripts\demarrer-frontend-port-forward.ps1
```

### Option 2 : Commande Manuelle

Ouvrez un terminal PowerShell et exécutez :

```powershell
kubectl port-forward -n smarthome svc/frontend-service-nodeport 3000:3000
```

**⚠️ IMPORTANT** : Laissez ce terminal ouvert pendant que vous utilisez le frontend.

Puis accédez à : **http://localhost:3000**

## 🔧 Configuration Keycloak avec Port-Forward

Si vous utilisez `localhost:3000`, configurez Keycloak avec :

1. **Valid redirect URIs** : `http://localhost:3000/*`
2. **Web origins** : `http://localhost:3000`

## 🧪 Test

1. **Démarrer le port-forward** :
```powershell
kubectl port-forward -n smarthome svc/frontend-service-nodeport 3000:3000
```

2. **Ouvrir le navigateur** : `http://localhost:3000`

3. **Vérifier** : Le frontend devrait s'afficher

## 🔄 Alternative : Autoriser le Port dans le Firewall

Si vous préférez utiliser le NodePort directement :

```powershell
# Autoriser le port 30000 dans le firewall Windows
New-NetFirewallRule -DisplayName "Minikube NodePort 30000" -Direction Inbound -LocalPort 30000 -Protocol TCP -Action Allow
```

Puis réessayez d'accéder à `http://192.168.49.2:30000`.

## 📝 Note

- **Port-forward** : Plus simple, fonctionne toujours, URL fixe (`localhost:3000`)
- **NodePort** : Nécessite la configuration du firewall, URL variable (`192.168.49.2:30000`)

Pour le développement, **port-forward est recommandé**.

