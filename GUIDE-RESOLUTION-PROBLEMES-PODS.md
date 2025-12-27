# Guide de Résolution : Problèmes des Pods

## 🔴 Problèmes Identifiés

1. **PostgreSQL** : CrashLoopBackOff - Health checks échouent
2. **Keycloak** : Redémarre constamment - En cours de construction
3. **Tous les services** : Running mais pas Ready (0/1) - Probablement lié à PostgreSQL

## 🔧 Solution Étape par Étape

### ÉTAPE 1 : Corriger PostgreSQL (PRIORITÉ)

PostgreSQL redémarre à cause des health checks qui échouent. Le problème vient probablement des probes qui timeout.

#### Solution A : Redémarrer PostgreSQL proprement

```powershell
# Supprimer le pod pour forcer un redémarrage propre
kubectl delete pod -n smarthome postgres-bfc7995cc-dz2xj

# Attendre que le nouveau pod démarre
kubectl get pods -n smarthome -l app=postgres -w
```

#### Solution B : Vérifier et corriger les health checks

Si le problème persiste, les health checks peuvent être trop stricts. Vérifiez la configuration :

```powershell
# Vérifier la configuration actuelle
kubectl get deployment postgres -n smarthome -o yaml | Select-String -Pattern "livenessProbe|readinessProbe" -Context 5
```

### ÉTAPE 2 : Attendre que Keycloak termine sa construction

Keycloak est en train de construire avec le driver PostgreSQL. Cela peut prendre 3-5 minutes.

```powershell
# Vérifier les logs de Keycloak
kubectl logs -n smarthome keycloak-b9858cf94-rlssc --tail=20

# Attendre que vous voyiez "Starting Keycloak..." puis "Keycloak started"
```

**Ne redémarrez PAS Keycloak pendant la construction !**

### ÉTAPE 3 : Vérifier l'état après correction de PostgreSQL

Une fois PostgreSQL stable, les autres services devraient se connecter :

```powershell
# Vérifier l'état de tous les pods
kubectl get pods -n smarthome

# Vérifier les logs des services qui redémarrent
kubectl logs -n smarthome usage-collector-service-f7b68f78d-777wk --tail=50
kubectl logs -n smarthome peak-detector-service-55d645979b-9ljll --tail=50
```

### ÉTAPE 4 : Redémarrer les services si nécessaire

Si les services ne se connectent toujours pas après que PostgreSQL soit stable :

```powershell
# Redémarrer les services un par un
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
```

## 🎯 Actions Immédiates

### 1. Corriger PostgreSQL (FAIT MAINTENANT)

```powershell
# Supprimer le pod PostgreSQL pour forcer un redémarrage
kubectl delete pod -n smarthome postgres-bfc7995cc-dz2xj

# Surveiller le redémarrage
kubectl get pods -n smarthome -l app=postgres -w
```

### 2. Attendre Keycloak (NE PAS TOUCHER)

Laissez Keycloak terminer sa construction. Vérifiez les logs toutes les 2-3 minutes :

```powershell
kubectl logs -n smarthome keycloak-b9858cf94-rlssc --tail=10
```

### 3. Vérifier après 5 minutes

```powershell
# Vérifier l'état général
kubectl get pods -n smarthome

# Si PostgreSQL est stable, les autres services devraient se connecter
```

## 🔍 Diagnostic des Problèmes

### PostgreSQL - CrashLoopBackOff

**Cause probable** : Health checks qui timeout ou échouent

**Solution** :
1. Redémarrer le pod PostgreSQL
2. Si le problème persiste, vérifier les ressources disponibles (mémoire/CPU)
3. Vérifier que le volume persistant est accessible

### Services - Running mais pas Ready

**Cause probable** : 
- Ne peuvent pas se connecter à PostgreSQL
- Health checks échouent
- Problèmes de configuration

**Solution** :
1. Attendre que PostgreSQL soit stable
2. Vérifier les logs des services
3. Redémarrer les services si nécessaire

### Keycloak - Redémarre constamment

**Cause** : En cours de construction avec le driver PostgreSQL

**Solution** : Attendre que la construction se termine (3-5 minutes)

## ⚠️ Ordre de Priorité

1. **PostgreSQL** - Doit être stable en premier
2. **Keycloak** - Laisser finir la construction
3. **Services backend** - Se connecteront automatiquement une fois PostgreSQL stable

## 📊 Vérification Finale

Une fois tout corrigé, vous devriez voir :

```powershell
kubectl get pods -n smarthome
```

Tous les pods devraient être `1/1 Ready` et `Running` sans redémarrages constants.

