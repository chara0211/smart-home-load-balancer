# Solution : Keycloak CrashLoopBackOff - Driver PostgreSQL manquant

## Problème

Keycloak 23.0 en mode "optimized" nécessite que le driver PostgreSQL soit inclus dans l'image. Sans cela, Keycloak essaie d'utiliser H2 et génère l'erreur :

```
ERROR: URL format error; must be "jdbc:h2:..." but is "jdbc:postgresql://postgres-service:5432/keycloak"
```

## Solution

Keycloak doit être construit avec le driver PostgreSQL avant de démarrer. La solution est d'utiliser la commande `build` pour ajouter le driver PostgreSQL.

### Configuration appliquée

Le déploiement Keycloak a été modifié pour construire automatiquement avec le driver PostgreSQL au premier démarrage :

```yaml
command:
- /bin/bash
- -c
- |
  if [ ! -f /opt/keycloak/lib/quarkus/datasource/deployment/agroal/runtime/main/quarkus-agroal.jar ]; then
    echo "Building Keycloak with PostgreSQL driver..."
    /opt/keycloak/bin/kc.sh build --db=postgres
  fi
  echo "Starting Keycloak..."
  /opt/keycloak/bin/kc.sh start --optimized --hostname-strict=false --hostname-strict-https=false
```

### Vérification

```bash
# Vérifier l'état du pod
kubectl get pods -n smarthome -l app=keycloak

# Vérifier les logs (la construction peut prendre 3-5 minutes)
kubectl logs -n smarthome -l app=keycloak --tail=50

# Attendre que Keycloak soit prêt
kubectl wait --for=condition=ready pod -l app=keycloak -n smarthome --timeout=600s
```

### Note importante

- La première construction prend 3-5 minutes
- Les redémarrages suivants seront plus rapides car la construction est mise en cache
- Si le pod redémarre, la construction sera vérifiée à nouveau mais sera rapide si déjà faite

### État attendu

Une fois la construction terminée, vous devriez voir dans les logs :
```
Starting Keycloak...
Keycloak started in X.XXX seconds
```

Ensuite, le pod devrait passer à l'état `Ready`.


