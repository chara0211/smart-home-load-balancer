# Actions Immédiates à Faire

## ✅ ÉTAPE 1 : PostgreSQL est maintenant corrigé

PostgreSQL devrait maintenant être stable. Les health checks ont été ajustés.

## 🔄 ÉTAPE 2 : Attendre que les services se reconnectent

Les services backend devraient automatiquement se reconnecter à PostgreSQL maintenant qu'il est stable. Attendez 1-2 minutes.

## ⏳ ÉTAPE 3 : Keycloak - NE PAS TOUCHER

Keycloak est en train de construire avec le driver PostgreSQL. **NE REDÉMARREZ PAS Keycloak !**

Cela peut prendre 3-5 minutes. Vérifiez les logs toutes les 2-3 minutes :

```powershell
kubectl logs -n smarthome keycloak-b9858cf94-rlssc --tail=10
```

Vous devriez voir :
- "Building Keycloak with PostgreSQL driver..." (en cours)
- "Starting Keycloak..." (après la construction)
- "Keycloak started in X.XXX seconds" (prêt)

## 📊 ÉTAPE 4 : Vérifier l'état après 5 minutes

```powershell
# Vérifier tous les pods
kubectl get pods -n smarthome

# Vérifier les services qui redémarrent encore
kubectl logs -n smarthome usage-collector-service-f7b68f78d-777wk --tail=30
```

## 🔧 Si les services ne se reconnectent pas

Si après 5 minutes, les services sont toujours en Running mais pas Ready :

```powershell
# Redémarrer les services un par un
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
```

## ⚠️ IMPORTANT

1. **PostgreSQL** : ✅ Corrigé - devrait être stable maintenant
2. **Keycloak** : ⏳ En construction - NE PAS TOUCHER pendant 3-5 minutes
3. **Services** : 🔄 Devraient se reconnecter automatiquement

## 🎯 Résultat Attendu

Après 5-10 minutes, vous devriez voir :

```
NAME                                        READY   STATUS    RESTARTS   AGE
postgres-xxx                                1/1     Running   0          Xm
keycloak-xxx                                1/1     Running   0          Xm
usage-collector-service-xxx                1/1     Running   0          Xm
peak-detector-service-xxx                   1/1     Running   0          Xm
...
```

Tous les pods devraient être `1/1 Ready` et `Running`.

