# Guide : Tester les Connexions dans Kubernetes

Ce guide explique comment tester que tous les composants de votre cluster Kubernetes communiquent correctement entre eux.

---

## 📋 Prérequis

- Cluster Kubernetes en cours d'exécution
- `kubectl` installé et configuré
- Tous les pods déployés dans le namespace `smarthome`

---

## 🧪 Tests de Connexion

### 1. Vérifier l'état des Pods et Services

```powershell
# Voir tous les pods
kubectl get pods -n smarthome

# Voir tous les services
kubectl get services -n smarthome

# Voir les endpoints (pods derrière chaque service)
kubectl get endpoints -n smarthome
```

**Résultat attendu :** Tous les pods doivent être `Running` et `READY 1/1`.

---

### 2. Test de Connexion à PostgreSQL

#### A. Depuis un pod usage-collector

```powershell
# Obtenir le nom du pod (celui qui est Running, pas Pending)
$pod = kubectl get pods -n smarthome -l app=usage-collector-service --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}'
Write-Host "Pod utilisé: $pod"

# Test de résolution DNS
kubectl exec $pod -n smarthome -- nslookup postgres-service

# Note: Les erreurs NXDOMAIN sont normales, l'important est que le service soit résolu
# Vous devriez voir: "Name: postgres-service.smarthome.svc.cluster.local"

# Test de connexion TCP
kubectl exec $pod -n smarthome -- nc -zv postgres-service 5432
```

**Résultat attendu :** 
- DNS résolu vers l'IP du service PostgreSQL
- Connexion TCP réussie sur le port 5432

#### B. Vérifier dans les logs

```powershell
# Voir les logs pour vérifier la connexion à PostgreSQL
kubectl logs $pod -n smarthome | Select-String -Pattern "database|postgres|HikariPool"
```

**Résultat attendu :** Messages comme `HikariPool-1 - Start completed` ou `Connected to database`.

---

### 3. Test de Connexion à RabbitMQ

#### A. Depuis un pod usage-collector

```powershell
# Test de résolution DNS
kubectl exec $pod -n smarthome -- nslookup rabbitmq-service

# Test de connexion TCP au port AMQP (5672)
kubectl exec $pod -n smarthome -- nc -zv rabbitmq-service 5672

# Test de connexion TCP au port Management (15672)
kubectl exec $pod -n smarthome -- nc -zv rabbitmq-service 15672
```

**Résultat attendu :** Connexions TCP réussies sur les deux ports.

#### B. Test depuis le pod RabbitMQ

```powershell
# Obtenir le pod RabbitMQ
$rabbitmqPod = kubectl get pods -n smarthome -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}'

# Test ping RabbitMQ
kubectl exec $rabbitmqPod -n smarthome -- rabbitmq-diagnostics ping
```

**Résultat attendu :** `Ping succeeded`

#### C. Vérifier dans les logs

```powershell
# Voir les logs pour vérifier la connexion à RabbitMQ
kubectl logs $pod -n smarthome | Select-String -Pattern "rabbitmq|RabbitMQ|Connection"
```

**Résultat attendu :** Messages comme `Created new connection` ou `Connected to RabbitMQ`.

---

### 4. Test de Communication entre Services

#### A. Test peak-detector → usage-collector

```powershell
# Obtenir le pod peak-detector
$peakPod = kubectl get pods -n smarthome -l app=peak-detector-service -o jsonpath='{.items[0].metadata.name}'

# Test de résolution DNS
kubectl exec $peakPod -n smarthome -- nslookup usage-collector-service

# Test de connexion HTTP
kubectl exec $peakPod -n smarthome -- wget -q --spider --timeout=5 http://usage-collector-service:8083/actuator/health
```

**Résultat attendu :** Connexion HTTP réussie (code 200).

---

### 5. Test des Endpoints HTTP (Health Checks)

#### A. Usage Collector Service

```powershell
# Test depuis le pod lui-même
kubectl exec $pod -n smarthome -- wget -q -O- http://localhost:8083/actuator/health

# Ou via port-forward depuis votre machine
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome
# Dans un autre terminal :
curl http://localhost:8083/actuator/health
```

**Résultat attendu :** JSON avec `"status":"UP"`

#### B. Peak Detector Service

```powershell
$peakPod = kubectl get pods -n smarthome -l app=peak-detector-service -o jsonpath='{.items[0].metadata.name}'
kubectl exec $peakPod -n smarthome -- wget -q -O- http://localhost:8084/actuator/health
```

#### C. Optimizer Service

```powershell
$optPod = kubectl get pods -n smarthome -l app=optimizer-service -o jsonpath='{.items[0].metadata.name}'
kubectl exec $optPod -n smarthome -- wget -q -O- http://localhost:8085/actuator/health
```

#### D. Device Simulator Service

```powershell
$devPod = kubectl get pods -n smarthome -l app=device-simulator-service -o jsonpath='{.items[0].metadata.name}'
kubectl exec $devPod -n smarthome -- wget -q -O- http://localhost:8082/actuator/health
```

---

### 6. Test via Port-Forward (Accès Local)

Pour tester depuis votre machine Windows, utilisez `port-forward` :

#### A. Usage Collector Service

```powershell
# Terminal 1 : Port-forward
kubectl port-forward service/usage-collector-service 8083:8083 -n smarthome

# Terminal 2 : Test
curl http://localhost:8083/actuator/health
# Ou dans le navigateur : http://localhost:8083/actuator/health
```

#### B. RabbitMQ Management Interface

```powershell
# Terminal 1 : Port-forward
kubectl port-forward service/rabbitmq-service 15672:15672 -n smarthome

# Terminal 2 : Ouvrir dans le navigateur
# http://localhost:15672
# Username: guest
# Password: guest
```

#### C. PostgreSQL

```powershell
# Terminal 1 : Port-forward
kubectl port-forward service/postgres-service 5432:5432 -n smarthome

# Terminal 2 : Connexion avec psql (si installé)
psql -h localhost -U smarthome -d smarthome
```

---

### 7. Test des Variables d'Environnement

Vérifier que les variables d'environnement sont correctement injectées :

```powershell
# Voir les variables d'environnement d'un pod
kubectl exec $pod -n smarthome -- env | Select-String -Pattern "SPRING|POSTGRES|RABBITMQ"
```

**Résultat attendu :** Variables comme :
- `SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-service:5432/smarthome`
- `SPRING_RABBITMQ_HOST=rabbitmq-service`
- `SPRING_RABBITMQ_PORT=5672`

---

### 8. Test de Communication via RabbitMQ

#### A. Vérifier les queues dans RabbitMQ

```powershell
# Port-forward RabbitMQ Management
kubectl port-forward service/rabbitmq-service 15672:15672 -n smarthome

# Accéder à http://localhost:15672
# Vérifier l'onglet "Queues" pour voir les queues créées
```

#### B. Vérifier dans les logs

```powershell
# Logs usage-collector
kubectl logs $pod -n smarthome | Select-String -Pattern "queue|exchange|binding"

# Logs peak-detector
kubectl logs $peakPod -n smarthome | Select-String -Pattern "queue|exchange|message"
```

---

### 9. Test Complet avec un Script Automatisé

Exécutez le script de test (si vous avez Git Bash ou WSL) :

```bash
# Dans Git Bash ou WSL
./scripts/test-kubernetes-connections.sh
```

---

## 🔍 Commandes de Débogage

### Voir les événements récents

```powershell
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 20
```

### Décrire un pod (diagnostic complet)

```powershell
kubectl describe pod <pod-name> -n smarthome
```

### Exécuter une commande dans un pod

```powershell
# Ouvrir un shell dans le pod
kubectl exec -it <pod-name> -n smarthome -- /bin/sh

# Tester une connexion depuis le pod
nc -zv postgres-service 5432
nc -zv rabbitmq-service 5672
wget -O- http://usage-collector-service:8083/actuator/health
```

### Voir les logs en temps réel

```powershell
# Logs d'un pod spécifique
kubectl logs -f <pod-name> -n smarthome

# Logs d'un déploiement
kubectl logs -f deployment/usage-collector-service -n smarthome
```

---

## ✅ Checklist de Vérification

- [ ] Tous les pods sont `Running` et `READY 1/1`
- [ ] Les services sont créés et ont des endpoints
- [ ] Connexion PostgreSQL réussie depuis usage-collector
- [ ] Connexion RabbitMQ réussie depuis tous les services
- [ ] Communication HTTP entre peak-detector et usage-collector
- [ ] Health checks retournent `"status":"UP"`
- [ ] Variables d'environnement correctement injectées
- [ ] Logs ne montrent pas d'erreurs de connexion

---

## 🐛 Problèmes Courants

### Erreur : "Connection refused"

**Cause :** Le service n'est pas encore prêt ou le port est incorrect.

**Solution :**
```powershell
# Vérifier que le pod est prêt
kubectl get pods -n smarthome

# Vérifier les logs
kubectl logs <pod-name> -n smarthome
```

### Erreur : "Name resolution failed"

**Cause :** Le service DNS n'est pas accessible ou le nom du service est incorrect.

**Solution :**
```powershell
# Vérifier que le service existe
kubectl get services -n smarthome

# Vérifier les endpoints
kubectl get endpoints -n smarthome
```

### Erreur : "Authentication failed" (PostgreSQL/RabbitMQ)

**Cause :** Les secrets ne sont pas correctement configurés.

**Solution :**
```powershell
# Vérifier les secrets
kubectl get secrets -n smarthome

# Vérifier les variables d'environnement du pod
kubectl exec <pod-name> -n smarthome -- env | Select-String -Pattern "PASSWORD|USERNAME"
```

---

## 📊 Résumé

Une fois tous ces tests réussis, vous pouvez être sûr que :

1. ✅ PostgreSQL est accessible depuis les microservices
2. ✅ RabbitMQ est accessible depuis tous les services
3. ✅ Les services peuvent communiquer entre eux via HTTP
4. ✅ Les health checks fonctionnent
5. ✅ La configuration est correcte

Votre infrastructure Kubernetes est opérationnelle ! 🚀

