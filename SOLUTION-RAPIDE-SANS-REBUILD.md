# Solution Rapide : Sans Rebuild (Temporaire)

## 🔴 Problème

Les services Spring Boot retournent **401 Unauthorized** sur les endpoints `/actuator/health/readiness` car ils sont protégés par Spring Security.

## ✅ Solution Temporaire : Utiliser /actuator/health

**Sans rebuild**, vous pouvez modifier temporairement les déploiements pour utiliser `/actuator/health` au lieu de `/actuator/health/readiness`.

### Script de Correction Rapide

```powershell
# Appliquer les configurations avec /actuator/health
kubectl apply -f k8s/services/billing/deployment.yaml
kubectl apply -f k8s/services/usage-collector/deployment.yaml
kubectl apply -f k8s/services/optimizer/deployment.yaml
kubectl apply -f k8s/services/peak-detector/deployment.yaml
kubectl apply -f k8s/services/device-simulator/deployment.yaml

# Redémarrer les services
kubectl rollout restart deployment/billing-service -n smarthome
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
```

### Modification des Déploiements

Modifiez temporairement les readiness probes pour utiliser `/actuator/health` :

```yaml
readinessProbe:
  httpGet:
    path: /actuator/health  # Au lieu de /actuator/health/readiness
    port: 8086
```

**Note** : `/actuator/health` est déjà autorisé dans les SecurityConfig existants.

## ⚠️ Solution Définitive

Pour une solution définitive, vous devez :
1. **Rebuild les images Docker** avec les SecurityConfig corrigés
2. **Push les images** vers le registry
3. **Redémarrer les services**

Voir `SOLUTION-FINALE-SERVICES-SPRING-BOOT.md` pour les détails.

## 🎯 Recommandation

**Pour le développement** : Utilisez Docker Compose qui n'a pas ces problèmes :
```powershell
.\scripts\migrer-vers-docker-compose.ps1
```

**Pour la production** : Rebuild les images avec les corrections.

