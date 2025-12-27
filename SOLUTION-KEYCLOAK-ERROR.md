# Solution : Erreur Keycloak "Unknown option: --proxy-headers"

## Problème

Keycloak 23.0 ne reconnaît pas l'option `--proxy-headers=xforwarded` et génère l'erreur :
```
Unknown option: '--proxy-headers'
```

## Solution

L'option `--proxy-headers=xforwarded` a été remplacée dans Keycloak 23.0. Il faut utiliser une variable d'environnement à la place.

### Correction appliquée

**Avant** (ne fonctionne pas) :
```yaml
args:
- start
- --optimized
- --hostname-strict=false
- --hostname-strict-https=false
- --proxy-headers=xforwarded  # ❌ Cette option n'existe plus
```

**Après** (fonctionne) :
```yaml
args:
- start
- --optimized
- --hostname-strict=false
- --hostname-strict-https=false
# L'option --proxy-headers a été supprimée

env:
- name: KC_PROXY
  value: "edge"  # ✅ Utiliser une variable d'environnement
```

## Vérification

```bash
# Vérifier que Keycloak démarre
kubectl get pods -n smarthome -l app=keycloak

# Vérifier les logs (attendre 2-3 minutes pour le démarrage complet)
kubectl logs -n smarthome -l app=keycloak --tail=50

# Attendre que le pod soit Ready
kubectl wait --for=condition=ready pod -l app=keycloak -n smarthome --timeout=300s
```

## Note

Keycloak prend généralement 2-3 minutes pour démarrer complètement. Le message d'avertissement "The following build time non-cli properties were found" est normal et peut être ignoré.


