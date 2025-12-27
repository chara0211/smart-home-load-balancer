# Guide de Diagnostic : Pods Non Prêts (0/1 Ready)

## 🔴 Problème

Vos pods sont en état `Running` mais affichent `0/1 Ready`, ce qui signifie que les **readiness probes** échouent. Les pods ne sont donc pas considérés comme prêts à recevoir du trafic.

## 🔍 Causes Possibles

### 1. **Readiness Probes Échouent**
Les endpoints de santé (`/actuator/health/readiness`) ne répondent pas correctement ou retournent une erreur.

**Causes courantes :**
- L'application Spring Boot n'a pas encore démarré complètement
- L'application ne peut pas se connecter aux dépendances (PostgreSQL, RabbitMQ, Keycloak)
- L'endpoint `/actuator/health/readiness` n'est pas configuré ou ne fonctionne pas
- Problèmes de configuration Spring Boot Actuator

### 2. **Dépendances Non Disponibles**
Les services dépendent de PostgreSQL, RabbitMQ ou Keycloak qui ne sont pas prêts.

**Symptômes :**
- Les pods redémarrent constamment (RESTARTS élevé)
- Erreurs de connexion dans les logs
- Timeout lors des tentatives de connexion

### 3. **Problèmes de Ressources (Pods Pending)**
Les pods en état `Pending` indiquent un problème de ressources ou de scheduling.

**Causes :**
- CPU ou mémoire insuffisants dans le cluster
- Aucun nœud disponible pour planifier le pod
- Problèmes avec les PersistentVolumeClaims

### 4. **Configuration Incorrecte**
- Secrets manquants ou incorrects
- ConfigMaps manquants
- Variables d'environnement incorrectes

## 🔧 Diagnostic Étape par Étape

### ÉTAPE 1 : Exécuter le Script de Diagnostic

```powershell
.\scripts\diagnostic-pods-not-ready.ps1
```

Ce script va :
- Lister tous les pods non prêts
- Afficher les événements récents
- Vérifier les ressources disponibles
- Diagnostiquer chaque pod individuellement
- Vérifier les dépendances (PostgreSQL, RabbitMQ, Keycloak)
- Vérifier les secrets et configmaps

### ÉTAPE 2 : Vérifier les Logs des Pods

Pour chaque pod non prêt, vérifiez les logs :

```powershell
# Exemple pour billing-service
kubectl logs -n smarthome billing-service-6c6f9d855-tfg9m --tail=50

# Pour tous les pods d'un service
kubectl logs -n smarthome -l app=billing-service --tail=50
```

**Cherchez :**
- Erreurs de connexion à PostgreSQL
- Erreurs de connexion à RabbitMQ
- Erreurs de connexion à Keycloak
- Erreurs de démarrage Spring Boot
- Timeout sur les health checks

### ÉTAPE 3 : Vérifier les Événements

```powershell
# Événements pour un pod spécifique
kubectl describe pod -n smarthome billing-service-6c6f9d855-tfg9m

# Tous les événements récents
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 30
```

**Cherchez :**
- `Readiness probe failed`
- `Liveness probe failed`
- `Failed to pull image`
- `Insufficient memory` ou `Insufficient cpu`
- `FailedMount` (problèmes de volumes)

### ÉTAPE 4 : Tester les Endpoints de Santé Manuellement

```powershell
# Tester l'endpoint de readiness
kubectl exec -n smarthome billing-service-6c6f9d855-tfg9m -- curl -s http://localhost:8086/actuator/health/readiness

# Tester l'endpoint de health général
kubectl exec -n smarthome billing-service-6c6f9d855-tfg9m -- curl -s http://localhost:8086/actuator/health
```

**Si les endpoints ne répondent pas :**
- L'application n'a pas démarré
- Le port est incorrect
- L'endpoint n'est pas configuré

### ÉTAPE 5 : Vérifier les Dépendances

```powershell
# Vérifier PostgreSQL
kubectl get pods -n smarthome -l app=postgres
kubectl logs -n smarthome -l app=postgres --tail=20

# Vérifier RabbitMQ
kubectl get pods -n smarthome -l app=rabbitmq
kubectl logs -n smarthome -l app=rabbitmq --tail=20

# Vérifier Keycloak
kubectl get pods -n smarthome -l app=keycloak
kubectl logs -n smarthome -l app=keycloak --tail=20
```

**Les dépendances doivent être prêtes AVANT les services qui en dépendent.**

## ✅ Solutions par Type de Problème

### Solution 1 : Readiness Probe Échoue - Application Non Démarrée

**Symptômes :**
- Pod en `Running` mais `0/1 Ready`
- Logs montrent que l'application démarre encore
- Readiness probe timeout

**Solution :**

1. **Augmenter le `initialDelaySeconds` de la readiness probe** dans le déploiement :

```yaml
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8086
  initialDelaySeconds: 60  # Augmenter de 30 à 60
  periodSeconds: 10         # Augmenter de 5 à 10
  timeoutSeconds: 5          # Augmenter de 3 à 5
  failureThreshold: 5        # Augmenter de 3 à 5
```

2. **Vérifier que l'application démarre correctement** :

```powershell
kubectl logs -n smarthome <pod-name> -f
```

Attendez de voir `Started <ServiceName>Application` dans les logs.

### Solution 2 : Readiness Probe Échoue - Dépendances Non Disponibles

**Symptômes :**
- Erreurs de connexion dans les logs
- `Connection refused` ou `Connection timeout`
- Pods redémarrent constamment

**Solution :**

1. **Vérifier que les dépendances sont prêtes** :

```powershell
# PostgreSQL doit être 1/1 Ready
kubectl get pods -n smarthome -l app=postgres

# RabbitMQ doit être 1/1 Ready
kubectl get pods -n smarthome -l app=rabbitmq

# Keycloak doit être 1/1 Ready (peut prendre 5-10 minutes)
kubectl get pods -n smarthome -l app=keycloak
```

2. **Si les dépendances ne sont pas prêtes, les corriger d'abord** :

```powershell
# Redémarrer PostgreSQL si nécessaire
kubectl delete pod -n smarthome -l app=postgres

# Redémarrer RabbitMQ si nécessaire
kubectl delete pod -n smarthome -l app=rabbitmq
```

3. **Attendre que les dépendances soient prêtes avant de redémarrer les services** :

```powershell
# Attendre que PostgreSQL soit prêt
kubectl wait --for=condition=ready pod -n smarthome -l app=postgres --timeout=300s

# Attendre que RabbitMQ soit prêt
kubectl wait --for=condition=ready pod -n smarthome -l app=rabbitmq --timeout=300s
```

4. **Redémarrer les services après que les dépendances soient prêtes** :

```powershell
kubectl rollout restart deployment/billing-service -n smarthome
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome
```

### Solution 3 : Pods en Pending - Ressources Insuffisantes

**Symptômes :**
- Pods en état `Pending`
- Événements montrent `Insufficient cpu` ou `Insufficient memory`

**Solution :**

1. **Vérifier les ressources disponibles** :

```powershell
kubectl describe nodes
kubectl top nodes
```

2. **Réduire les ressources demandées** dans les déploiements :

```yaml
resources:
  requests:
    memory: "256Mi"  # Réduire de 768Mi
    cpu: "250m"      # Réduire de 500m
  limits:
    memory: "1Gi"    # Réduire de 2Gi
    cpu: "500m"      # Réduire de 1000m
```

3. **Ou réduire le nombre de replicas** :

```yaml
spec:
  replicas: 1  # Réduire de 2 à 1
```

4. **Supprimer les pods Pending et laisser Kubernetes les replanifier** :

```powershell
kubectl delete pod -n smarthome <pending-pod-name>
```

### Solution 4 : Readiness Probe - Endpoint Non Configuré

**Symptômes :**
- Readiness probe retourne 404
- L'endpoint `/actuator/health/readiness` n'existe pas

**Solution :**

1. **Vérifier la configuration Spring Boot Actuator** dans `application.properties` ou `application.yml` :

```properties
# Activer les endpoints de santé
management.endpoints.web.exposure.include=health,info
management.endpoint.health.probes.enabled=true
management.endpoint.health.show-details=always
```

2. **Vérifier que les dépendances sont dans `pom.xml`** :

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

3. **Utiliser l'endpoint `/actuator/health` au lieu de `/actuator/health/readiness`** si les probes ne sont pas activées :

```yaml
readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8086
```

### Solution 5 : Secrets ou ConfigMaps Manquants

**Symptômes :**
- Erreurs `secret not found` ou `configmap not found` dans les événements
- Application ne démarre pas

**Solution :**

1. **Vérifier que les secrets existent** :

```powershell
kubectl get secrets -n smarthome
```

2. **Vérifier que les configmaps existent** :

```powershell
kubectl get configmaps -n smarthome
```

3. **Créer les secrets manquants** :

```powershell
# Vérifier le template
kubectl get secret -n smarthome postgres-secret -o yaml
```

## 🎯 Plan d'Action Recommandé

### Ordre de Priorité

1. **PostgreSQL** - Doit être prêt en premier
2. **RabbitMQ** - Doit être prêt en deuxième
3. **Keycloak** - Peut prendre 5-10 minutes (ne pas redémarrer pendant la construction)
4. **Services backend** - Se connecteront automatiquement une fois les dépendances prêtes

### Actions Immédiates

```powershell
# 1. Vérifier l'état de PostgreSQL
kubectl get pods -n smarthome -l app=postgres
kubectl logs -n smarthome -l app=postgres --tail=20

# 2. Si PostgreSQL n'est pas prêt, le redémarrer
kubectl delete pod -n smarthome -l app=postgres
kubectl wait --for=condition=ready pod -n smarthome -l app=postgres --timeout=300s

# 3. Vérifier RabbitMQ
kubectl get pods -n smarthome -l app=rabbitmq
kubectl logs -n smarthome -l app=rabbitmq --tail=20

# 4. Si RabbitMQ n'est pas prêt, le redémarrer
kubectl delete pod -n smarthome -l app=rabbitmq
kubectl wait --for=condition=ready pod -n smarthome -l app=rabbitmq --timeout=300s

# 5. Attendre que Keycloak soit prêt (ne pas redémarrer si en cours de construction)
kubectl logs -n smarthome -l app=keycloak --tail=20

# 6. Une fois les dépendances prêtes, redémarrer les services
kubectl rollout restart deployment/billing-service -n smarthome
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome

# 7. Surveiller le démarrage
kubectl get pods -n smarthome -w
```

## 📊 Vérification Finale

Après avoir appliqué les solutions, vérifiez que tous les pods sont prêts :

```powershell
kubectl get pods -n smarthome
```

Tous les pods devraient afficher `1/1 Ready` et `Running` sans redémarrages constants.

## 🔍 Commandes Utiles

```powershell
# Voir l'état détaillé d'un pod
kubectl describe pod -n smarthome <pod-name>

# Suivre les logs en temps réel
kubectl logs -n smarthome <pod-name> -f

# Voir les événements pour un pod
kubectl get events -n smarthome --field-selector involvedObject.name=<pod-name>

# Tester un endpoint de santé
kubectl exec -n smarthome <pod-name> -- curl -s http://localhost:<port>/actuator/health

# Voir la configuration d'un déploiement
kubectl get deployment -n smarthome <deployment-name> -o yaml

# Redémarrer un déploiement
kubectl rollout restart deployment/<deployment-name> -n smarthome

# Voir l'historique des déploiements
kubectl rollout history deployment/<deployment-name> -n smarthome
```




