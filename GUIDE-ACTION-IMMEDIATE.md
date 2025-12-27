# Guide d'Action Immédiate - Résolution des Pods Non Prêts

## 🔴 Situation Actuelle

- **RabbitMQ** : En Pending (mémoire insuffisante)
- **Plusieurs services** : En Pending (mémoire insuffisante)
- **Services Spring Boot** : Running mais 0/1 Ready (ne peuvent pas se connecter à RabbitMQ)
- **Keycloak** : Running mais 0/1 Ready

## ✅ Plan d'Action Immédiat

### ÉTAPE 1 : Exécuter le Script de Correction

```powershell
.\scripts\correction-complete-cluster.ps1
```

Ce script va :
- Nettoyer les pods en Pending et en erreur
- S'assurer qu'il n'y a qu'un seul replica par service
- Libérer de la mémoire
- Vérifier l'état des dépendances

### ÉTAPE 2 : Surveiller RabbitMQ (PRIORITÉ)

RabbitMQ est la dépendance critique. Une fois qu'il est prêt, les autres services pourront se connecter.

```powershell
# Surveiller RabbitMQ en temps réel
kubectl get pods -n smarthome -l app=rabbitmq -w
```

**Attendez que RabbitMQ passe à `1/1 Ready` et `Running`** (peut prendre 2-5 minutes).

### ÉTAPE 3 : Si RabbitMQ Reste en Pending

#### Option A : Attendre (Recommandé)

Les pods vont progressivement libérer de la mémoire. Attendez 5-10 minutes et vérifiez à nouveau :

```powershell
kubectl get pods -n smarthome -l app=rabbitmq
```

#### Option B : Augmenter les Ressources Minikube

Si vous avez assez de RAM sur votre machine :

```powershell
# Arrêter Minikube
minikube stop

# Redémarrer avec plus de ressources
minikube start --memory=4096 --cpus=4

# Vérifier que Minikube a démarré
kubectl get nodes
```

#### Option C : Réduire Encore Plus les Ressources RabbitMQ

Si vraiment nécessaire, réduisez à 256Mi (minimum absolu) :

```yaml
# Dans k8s/message-broker/rabbitmq-deployment.yaml
resources:
  requests:
    memory: "256Mi"  # Au lieu de 512Mi
    cpu: "100m"
```

Puis appliquez :
```powershell
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl delete pod -n smarthome -l app=rabbitmq --grace-period=0 --force
```

### ÉTAPE 4 : Une Fois RabbitMQ Prêt

Une fois RabbitMQ est `1/1 Ready`, les services Spring Boot devraient automatiquement :
1. Se connecter à RabbitMQ
2. Passer leurs readiness probes
3. Devenir `1/1 Ready`

**Surveillez tous les pods :**
```powershell
kubectl get pods -n smarthome -w
```

### ÉTAPE 5 : Vérification Finale

Après 5-10 minutes, vérifiez l'état :

```powershell
kubectl get pods -n smarthome
```

**Résultat attendu :**
- ✅ PostgreSQL : `1/1 Ready`
- ✅ RabbitMQ : `1/1 Ready`
- ✅ Services Spring Boot : `1/1 Ready` (une fois RabbitMQ prêt)
- ✅ Keycloak : `1/1 Ready` (peut prendre plus de temps)

## 🔍 Diagnostic si Problème Persiste

### Vérifier les Logs

```powershell
# RabbitMQ
kubectl logs -n smarthome -l app=rabbitmq --tail=50

# Un service spécifique
kubectl logs -n smarthome <pod-name> --tail=50
```

### Vérifier les Événements

```powershell
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 30
```

### Vérifier les Ressources

```powershell
kubectl describe node
```

## 📝 Ordre de Priorité

1. **RabbitMQ** - Doit être prêt en premier (bloque tous les services)
2. **PostgreSQL** - Déjà prêt ✅
3. **Services Spring Boot** - Se connecteront automatiquement une fois RabbitMQ prêt
4. **Keycloak** - Peut prendre 5-10 minutes

## ⚠️ Points Importants

- **Ne redémarrez PAS les pods manuellement** - Laissez Kubernetes gérer
- **Attendez patiemment** - Les pods peuvent prendre 2-5 minutes pour démarrer
- **RabbitMQ est critique** - Sans lui, aucun service Spring Boot ne fonctionnera
- **Mémoire limitée** - Le cluster a des ressources limitées, c'est normal que certains pods soient en Pending

## 🎯 Résumé des Actions

1. ✅ Exécuter le script de correction
2. ⏳ Attendre que RabbitMQ devienne prêt (2-5 minutes)
3. ⏳ Attendre que les services Spring Boot se connectent (1-2 minutes après RabbitMQ)
4. ✅ Vérifier l'état final

**Temps total estimé : 5-10 minutes**


