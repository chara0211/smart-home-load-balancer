# Solution Définitive : Pods Non Prêts (0/1 Ready)

## 🔴 Problème

Vos pods affichent `0/1 Ready` avec plusieurs problèmes critiques :
- **PostgreSQL en CrashLoopBackOff** (37 redémarrages)
- **Keycloak en Error** (15 redémarrages)
- **Services Spring Boot en CrashLoopBackOff** (optimizer: 100, peak-detector: 96)
- **Beaucoup de pods en Pending** (ressources insuffisantes)
- **RabbitMQ en Running mais 0/1 Ready** (readiness probe échoue)

## ✅ Solution Définitive

### Exécution Automatique

Exécutez simplement le script de correction :

```powershell
.\scripts\solution-definitive-pods-ready.ps1
```

Ce script va automatiquement :
1. ✅ Nettoyer tous les pods en erreur (CrashLoopBackOff, Error, Pending)
2. ✅ Vérifier les ressources disponibles
3. ✅ Corriger PostgreSQL (priorité absolue)
4. ✅ Corriger RabbitMQ
5. ✅ Attendre que les dépendances soient prêtes
6. ✅ Redémarrer tous les services Spring Boot
7. ✅ Vérifier Keycloak
8. ✅ Afficher l'état final

### Exécution Manuelle (Étape par Étape)

Si vous préférez faire les corrections manuellement :

#### ÉTAPE 1 : Nettoyer les Pods en Erreur

```powershell
# Supprimer tous les pods en CrashLoopBackOff
kubectl get pods -n smarthome -o json | ConvertFrom-Json | 
    ForEach-Object { $_.items } | 
    Where-Object { $_.status.containerStatuses[0].state.waiting.reason -eq "CrashLoopBackOff" } | 
    ForEach-Object { kubectl delete pod -n smarthome $_.metadata.name --grace-period=0 --force }

# Supprimer tous les pods en Error
kubectl get pods -n smarthome -o json | ConvertFrom-Json | 
    ForEach-Object { $_.items } | 
    Where-Object { $_.status.phase -eq "Failed" } | 
    ForEach-Object { kubectl delete pod -n smarthome $_.metadata.name --grace-period=0 --force }

# Supprimer tous les pods en Pending
kubectl get pods -n smarthome -o json | ConvertFrom-Json | 
    ForEach-Object { $_.items } | 
    Where-Object { $_.status.phase -eq "Pending" } | 
    ForEach-Object { kubectl delete pod -n smarthome $_.metadata.name --grace-period=0 --force }
```

#### ÉTAPE 2 : Corriger PostgreSQL (PRIORITÉ)

PostgreSQL est la dépendance critique. Tous les services en dépendent.

```powershell
# 1. Supprimer le pod PostgreSQL actuel
kubectl delete pod -n smarthome -l app=postgres --grace-period=0 --force

# 2. Appliquer la configuration améliorée
kubectl apply -f k8s/databases/postgres-deployment.yaml

# 3. Attendre que PostgreSQL soit prêt (peut prendre 2-3 minutes)
kubectl wait --for=condition=ready pod -n smarthome -l app=postgres --timeout=300s

# 4. Vérifier l'état
kubectl get pods -n smarthome -l app=postgres
kubectl logs -n smarthome -l app=postgres --tail=20
```

**Si PostgreSQL ne démarre toujours pas :**

```powershell
# Vérifier les événements
kubectl describe pod -n smarthome -l app=postgres

# Vérifier les logs
kubectl logs -n smarthome -l app=postgres --tail=100

# Vérifier le PVC
kubectl get pvc -n smarthome postgres-pvc
kubectl describe pvc -n smarthome postgres-pvc
```

#### ÉTAPE 3 : Corriger RabbitMQ

```powershell
# 1. Supprimer le pod RabbitMQ actuel
kubectl delete pod -n smarthome -l app=rabbitmq --grace-period=0 --force

# 2. Appliquer la configuration améliorée
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml

# 3. Attendre que RabbitMQ soit prêt (peut prendre 2-3 minutes)
kubectl wait --for=condition=ready pod -n smarthome -l app=rabbitmq --timeout=300s

# 4. Vérifier l'état
kubectl get pods -n smarthome -l app=rabbitmq
kubectl logs -n smarthome -l app=rabbitmq --tail=20
```

#### ÉTAPE 4 : Attendre que les Dépendances Soient Prêtes

```powershell
# Vérifier que PostgreSQL et RabbitMQ sont prêts
kubectl get pods -n smarthome -l 'app in (postgres,rabbitmq)'

# Les deux doivent afficher "1/1 Ready" et "Running"
```

#### ÉTAPE 5 : Redémarrer les Services Spring Boot

**IMPORTANT :** Ne redémarrez les services QUE lorsque PostgreSQL et RabbitMQ sont prêts.

```powershell
# Redémarrer tous les services Spring Boot
kubectl rollout restart deployment/billing-service -n smarthome
kubectl rollout restart deployment/usage-collector-service -n smarthome
kubectl rollout restart deployment/optimizer-service -n smarthome
kubectl rollout restart deployment/peak-detector-service -n smarthome
kubectl rollout restart deployment/device-simulator-service -n smarthome

# Surveiller le démarrage
kubectl get pods -n smarthome -w
```

#### ÉTAPE 6 : Vérifier Keycloak

```powershell
# Vérifier l'état de Keycloak
kubectl get pods -n smarthome -l app=keycloak

# Si Keycloak est en Error, le redémarrer
kubectl delete pod -n smarthome -l app=keycloak --grace-period=0 --force

# Keycloak peut prendre 5-10 minutes pour démarrer complètement
kubectl logs -n smarthome -l app=keycloak -f
```

## 🔍 Diagnostic des Problèmes Spécifiques

### PostgreSQL en CrashLoopBackOff

**Causes possibles :**
- Problème avec le PersistentVolumeClaim
- Problème de ressources (mémoire/CPU)
- Problème avec les probes (timeout trop court)
- Corruption des données

**Solutions :**

1. **Vérifier le PVC :**
```powershell
kubectl get pvc -n smarthome postgres-pvc
kubectl describe pvc -n smarthome postgres-pvc
```

2. **Vérifier les ressources :**
```powershell
kubectl top nodes
kubectl describe node
```

3. **Vérifier les logs :**
```powershell
kubectl logs -n smarthome -l app=postgres --tail=100
```

4. **Si le PVC est corrompu (dernier recours) :**
```powershell
# ⚠️ ATTENTION : Cela supprimera toutes les données PostgreSQL !
kubectl delete pvc -n smarthome postgres-pvc
kubectl apply -f k8s/databases/postgres-deployment.yaml
```

### Services Spring Boot en CrashLoopBackOff

**Causes possibles :**
- Ne peuvent pas se connecter à PostgreSQL
- Ne peuvent pas se connecter à RabbitMQ
- Ne peuvent pas se connecter à Keycloak
- Problèmes de configuration

**Solutions :**

1. **Vérifier les logs :**
```powershell
kubectl logs -n smarthome <pod-name> --tail=100
```

2. **Vérifier les connexions :**
```powershell
# Tester la connexion à PostgreSQL depuis un pod
kubectl exec -n smarthome <pod-name> -- nc -zv postgres-service 5432

# Tester la connexion à RabbitMQ
kubectl exec -n smarthome <pod-name> -- nc -zv rabbitmq-service 5672
```

3. **Vérifier les secrets et configmaps :**
```powershell
kubectl get secrets -n smarthome
kubectl get configmaps -n smarthome
```

### Pods en Pending

**Causes possibles :**
- Ressources insuffisantes (CPU/mémoire)
- Aucun nœud disponible
- Problème avec les PersistentVolumeClaims

**Solutions :**

1. **Vérifier les ressources :**
```powershell
kubectl describe node
kubectl top nodes
```

2. **Vérifier pourquoi un pod est en Pending :**
```powershell
kubectl describe pod -n smarthome <pod-name>
```

3. **Réduire les ressources demandées** dans les déploiements si nécessaire

4. **Réduire le nombre de replicas :**
```powershell
kubectl scale deployment/<deployment-name> -n smarthome --replicas=1
```

### RabbitMQ en Running mais 0/1 Ready

**Causes possibles :**
- Readiness probe timeout
- Problème de mémoire (alerte `system_memory_high_watermark`)
- RabbitMQ démarre lentement

**Solutions :**

1. **Vérifier les logs :**
```powershell
kubectl logs -n smarthome -l app=rabbitmq --tail=50
```

2. **Tester la readiness probe manuellement :**
```powershell
kubectl exec -n smarthome <rabbitmq-pod> -- rabbitmq-diagnostics ping
```

3. **La configuration améliorée devrait résoudre ce problème** (timeouts augmentés, mémoire limitée)

## 📊 Vérification Finale

Après avoir appliqué la solution, vérifiez que tous les pods sont prêts :

```powershell
kubectl get pods -n smarthome
```

**Résultat attendu :**
- Tous les pods affichent `1/1 Ready`
- Tous les pods sont en état `Running`
- Aucun pod en `CrashLoopBackOff`, `Error` ou `Pending`
- Les redémarrages (RESTARTS) sont à 0 ou très faibles

## 🎯 Commandes de Surveillance

```powershell
# Surveiller tous les pods en temps réel
kubectl get pods -n smarthome -w

# Voir les événements récents
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 30

# Voir les logs d'un service
kubectl logs -n smarthome -l app=<service-name> -f

# Voir l'état détaillé d'un pod
kubectl describe pod -n smarthome <pod-name>

# Vérifier les ressources utilisées
kubectl top pods -n smarthome
kubectl top nodes
```

## ⚠️ Points d'Attention

1. **Ordre de démarrage :** PostgreSQL → RabbitMQ → Services Spring Boot → Keycloak
2. **Ne redémarrez PAS Keycloak** s'il est en cours de construction (peut prendre 5-10 minutes)
3. **PostgreSQL est critique** : Si PostgreSQL ne fonctionne pas, aucun service ne fonctionnera
4. **Ressources** : Si vous avez beaucoup de pods en Pending, vérifiez les ressources disponibles
5. **Patience** : Les services peuvent prendre 2-5 minutes pour démarrer complètement

## 🔧 Améliorations Appliquées

Les configurations ont été améliorées pour résoudre les problèmes :

### PostgreSQL
- ✅ Timeouts des probes augmentés
- ✅ Seuils d'échec augmentés
- ✅ Configuration plus robuste

### RabbitMQ
- ✅ Limitation de l'utilisation mémoire (60% au lieu de laisser monter)
- ✅ Timeouts des probes augmentés
- ✅ Seuils d'échec augmentés
- ✅ Configuration pour éviter les alertes mémoire

## 📝 En Cas de Problème Persistant

Si les problèmes persistent après avoir exécuté la solution :

1. **Vérifiez les logs détaillés** de chaque service
2. **Vérifiez les événements Kubernetes** pour voir les erreurs
3. **Vérifiez les ressources** (CPU, mémoire, espace disque)
4. **Vérifiez les secrets et configmaps** (sont-ils corrects ?)
5. **Vérifiez la connectivité réseau** entre les pods

Pour obtenir de l'aide supplémentaire, exécutez :

```powershell
.\scripts\diagnostic-pods-not-ready.ps1
```

Ce script vous donnera un diagnostic complet de tous les problèmes.


