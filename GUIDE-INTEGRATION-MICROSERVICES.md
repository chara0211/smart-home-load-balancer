# Guide d'Intégration - Architecture Microservices avec Kubernetes

Ce guide explique comment intégrer toutes les technologies nécessaires pour transformer votre application en une architecture microservices complète avec Kubernetes, CI/CD, observabilité, sécurité et API Gateway.

## 📋 Table des matières

1. [Kubernetes - Orchestration](#1-kubernetes---orchestration)
2. [Pipeline CI/CD](#2-pipeline-cicd)
3. [Bases de données supplémentaires](#3-bases-de-données-supplémentaires)
4. [API Gateway](#4-api-gateway)
5. [Sécurité et Authentification (Keycloak)](#5-sécurité-et-authentification-keycloak)
6. [Observabilité](#6-observabilité)
7. [Déploiement complet](#7-déploiement-complet)

---

## 1. Kubernetes - Orchestration

### 1.1 Structure des manifests Kubernetes

Créez le dossier `k8s/` à la racine du projet avec la structure suivante :

```
k8s/
├── namespaces/
│   └── smarthome-namespace.yaml
├── configmaps/
│   ├── postgres-config.yaml
│   ├── rabbitmq-config.yaml
│   └── services-config.yaml
├── secrets/
│   └── secrets-template.yaml
├── databases/
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── cassandra-statefulset.yaml
│   └── cassandra-service.yaml
├── message-broker/
│   ├── rabbitmq-deployment.yaml
│   └── rabbitmq-service.yaml
├── services/
│   ├── usage-collector/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── peak-detector/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── device-simulator/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   └── optimizer/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── hpa.yaml
├── api-gateway/
│   ├── nginx-deployment.yaml
│   ├── nginx-service.yaml
│   └── nginx-configmap.yaml
├── keycloak/
│   ├── keycloak-deployment.yaml
│   └── keycloak-service.yaml
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus-deployment.yaml
│   │   ├── prometheus-service.yaml
│   │   └── prometheus-configmap.yaml
│   ├── grafana/
│   │   ├── grafana-deployment.yaml
│   │   ├── grafana-service.yaml
│   │   └── grafana-configmap.yaml
│   └── elastic/
│       ├── elasticsearch-statefulset.yaml
│       ├── elasticsearch-service.yaml
│       ├── kibana-deployment.yaml
│       └── kibana-service.yaml
└── ingress/
    └── ingress.yaml
```

### 1.2 Commandes de déploiement Kubernetes

```bash
# Créer le namespace
kubectl apply -f k8s/namespaces/

# Créer les secrets (après configuration)
kubectl apply -f k8s/secrets/

# Déployer les bases de données
kubectl apply -f k8s/databases/

# Déployer RabbitMQ
kubectl apply -f k8s/message-broker/

# Déployer les microservices
kubectl apply -f k8s/services/

# Déployer l'API Gateway
kubectl apply -f k8s/api-gateway/

# Déployer Keycloak
kubectl apply -f k8s/keycloak/

# Déployer l'observabilité
kubectl apply -f k8s/monitoring/

# Déployer l'ingress
kubectl apply -f k8s/ingress/
```

### 1.3 Vérification du déploiement

```bash
# Vérifier tous les pods
kubectl get pods -n smarthome

# Vérifier les services
kubectl get services -n smarthome

# Vérifier les logs d'un service
kubectl logs -f deployment/usage-collector-service -n smarthome

# Vérifier les événements
kubectl get events -n smarthome --sort-by='.lastTimestamp'
```

---

## 2. Pipeline CI/CD

### 2.1 GitLab CI/CD

Créez `.gitlab-ci.yml` à la racine du projet. Voir le fichier `gitlab-ci.yml` fourni.

**Utilisation :**
- Push automatique vers GitLab déclenche le pipeline
- Les images Docker sont construites et poussées vers un registry
- Le déploiement Kubernetes est automatique après les tests

### 2.2 Jenkins

Créez `Jenkinsfile` à la racine du projet. Voir le fichier `Jenkinsfile` fourni.

**Configuration Jenkins :**
1. Installer les plugins : Docker Pipeline, Kubernetes CLI, Git
2. Créer un pipeline Jenkins avec le Jenkinsfile
3. Configurer les credentials pour Docker registry et Kubernetes

### 2.3 CircleCI

Créez `.circleci/config.yml`. Voir le fichier `.circleci/config.yml` fourni.

**Configuration :**
1. Connecter votre repository GitHub/GitLab à CircleCI
2. Configurer les variables d'environnement dans CircleCI
3. Le pipeline se déclenche automatiquement

---

## 3. Bases de données supplémentaires

### 3.1 MongoDB

**Déploiement :**
```bash
kubectl apply -f k8s/databases/mongodb-deployment.yaml
kubectl apply -f k8s/databases/mongodb-service.yaml
```

**Utilisation :**
- MongoDB est disponible sur `mongodb-service:27017` dans le cluster
- Pour l'utiliser dans vos services, ajoutez la dépendance Spring Data MongoDB

### 3.2 Cassandra

**Déploiement :**
```bash
kubectl apply -f k8s/databases/cassandra-statefulset.yaml
kubectl apply -f k8s/databases/cassandra-service.yaml
```

**Utilisation :**
- Cassandra est disponible sur `cassandra-service:9042` dans le cluster
- Utilisez Spring Data Cassandra pour l'intégration

---

## 4. API Gateway

### 4.1 NGINX

**Déploiement :**
```bash
kubectl apply -f k8s/api-gateway/nginx-configmap.yaml
kubectl apply -f k8s/api-gateway/nginx-deployment.yaml
kubectl apply -f k8s/api-gateway/nginx-service.yaml
```

**Accès :**
- API Gateway disponible sur `http://api-gateway-service:80` (interne)
- Via Ingress : `http://your-domain/api/`

### 4.2 Kong (Alternative)

Si vous préférez Kong, utilisez les fichiers dans `k8s/api-gateway/kong/` :

```bash
kubectl apply -f k8s/api-gateway/kong/
```

**Avantages de Kong :**
- Gestion avancée des plugins
- Interface d'administration
- Rate limiting intégré

---

## 5. Sécurité et Authentification (Keycloak)

### 5.1 Déploiement Keycloak

```bash
kubectl apply -f k8s/keycloak/keycloak-deployment.yaml
kubectl apply -f k8s/keycloak/keycloak-service.yaml
```

### 5.2 Configuration initiale

1. Accéder à Keycloak : `http://keycloak-service:8080`
2. Créer un realm `smarthome`
3. Créer des clients pour chaque microservice
4. Configurer les rôles et utilisateurs

### 5.3 Intégration avec les microservices

Pour intégrer Keycloak dans vos services Spring Boot :

1. Ajouter la dépendance dans `pom.xml` :
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

2. Configuration dans `application.properties` :
```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=http://keycloak-service:8080/realms/smarthome
```

---

## 6. Observabilité

### 6.1 Prometheus - Collecte de métriques

**Déploiement :**
```bash
kubectl apply -f k8s/monitoring/prometheus/
```

**Accès :**
- Prometheus UI : `http://prometheus-service:9090`
- Via Ingress : `http://your-domain/prometheus`

**Configuration :**
- Les services Spring Boot doivent exposer des métriques Actuator
- Prometheus scrape automatiquement les endpoints `/actuator/prometheus`

### 6.2 Grafana - Visualisation

**Déploiement :**
```bash
kubectl apply -f k8s/monitoring/grafana/
```

**Accès :**
- Grafana UI : `http://grafana-service:3000`
- Login par défaut : `admin/admin` (à changer)

**Configuration :**
1. Ajouter Prometheus comme source de données
2. Importer les dashboards fournis dans `k8s/monitoring/grafana/dashboards/`

### 6.3 Elastic Stack - Logs

**Déploiement :**
```bash
# Elasticsearch (peut prendre quelques minutes)
kubectl apply -f k8s/monitoring/elastic/elasticsearch-statefulset.yaml
kubectl apply -f k8s/monitoring/elastic/elasticsearch-service.yaml

# Attendre que Elasticsearch soit prêt
kubectl wait --for=condition=ready pod -l app=elasticsearch -n smarthome --timeout=300s

# Kibana
kubectl apply -f k8s/monitoring/elastic/kibana-deployment.yaml
kubectl apply -f k8s/monitoring/elastic/kibana-service.yaml
```

**Accès :**
- Kibana UI : `http://kibana-service:5601`
- Via Ingress : `http://your-domain/kibana`

**Configuration :**
1. Configurer Filebeat ou Fluentd pour collecter les logs des pods
2. Créer des index patterns dans Kibana

---

## 7. Déploiement complet

### 7.1 Ordre de déploiement recommandé

```bash
# 1. Namespace et secrets
kubectl apply -f k8s/namespaces/
kubectl apply -f k8s/secrets/

# 2. Bases de données (attendre qu'elles soient prêtes)
kubectl apply -f k8s/databases/
kubectl wait --for=condition=ready pod -l app=postgres -n smarthome --timeout=300s

# 3. Message broker
kubectl apply -f k8s/message-broker/
kubectl wait --for=condition=ready pod -l app=rabbitmq -n smarthome --timeout=300s

# 4. Observabilité (en parallèle)
kubectl apply -f k8s/monitoring/

# 5. Keycloak
kubectl apply -f k8s/keycloak/
kubectl wait --for=condition=ready pod -l app=keycloak -n smarthome --timeout=300s

# 6. Microservices
kubectl apply -f k8s/services/

# 7. API Gateway
kubectl apply -f k8s/api-gateway/

# 8. Ingress (dernier)
kubectl apply -f k8s/ingress/
```

### 7.2 Script de déploiement automatique

Utilisez le script `scripts/deploy-all.sh` pour automatiser le déploiement :

```bash
chmod +x scripts/deploy-all.sh
./scripts/deploy-all.sh
```

### 7.3 Vérification post-déploiement

```bash
# Vérifier tous les pods
kubectl get pods -n smarthome

# Vérifier les services
kubectl get services -n smarthome

# Vérifier l'ingress
kubectl get ingress -n smarthome

# Tester l'API Gateway
curl http://your-domain/api/usage/current
```

---

## 8. Migration depuis Docker Compose

### 8.1 Étapes de migration

1. **Exporter les données PostgreSQL** (si nécessaire) :
```bash
docker exec smart-home-load-balancer-postgres pg_dump -U smarthome smarthome > backup.sql
```

2. **Créer les secrets Kubernetes** :
```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=smarthome \
  --from-literal=database=smarthome \
  -n smarthome
```

3. **Déployer sur Kubernetes** :
```bash
kubectl apply -f k8s/
```

4. **Importer les données** (si nécessaire) :
```bash
kubectl exec -it postgres-pod -n smarthome -- psql -U smarthome -d smarthome < backup.sql
```

### 8.2 Utilisation parallèle

Vous pouvez garder Docker Compose pour le développement local et utiliser Kubernetes pour la production :

- **Développement** : `docker-compose up`
- **Production** : Déploiement Kubernetes

---

## 9. Maintenance et opérations

### 9.1 Mise à jour d'un service

```bash
# Rebuild l'image
docker build -t salmaidoufkir/usage-collector-service:new-tag ./usage-collector-service
docker push salmaidoufkir/usage-collector-service:new-tag

# Mettre à jour le deployment
kubectl set image deployment/usage-collector-service \
  usage-collector-service=salmaidoufkir/usage-collector-service:new-tag \
  -n smarthome

# Vérifier le rollout
kubectl rollout status deployment/usage-collector-service -n smarthome
```

### 9.2 Scaling

```bash
# Scaling manuel
kubectl scale deployment/usage-collector-service --replicas=3 -n smarthome

# Scaling automatique (HPA)
kubectl apply -f k8s/services/usage-collector/hpa.yaml
```

### 9.3 Backup des bases de données

```bash
# PostgreSQL
kubectl exec -it postgres-pod -n smarthome -- \
  pg_dump -U smarthome smarthome > postgres-backup-$(date +%Y%m%d).sql

# MongoDB
kubectl exec -it mongodb-pod -n smarthome -- \
  mongodump --out /backup/mongodb-$(date +%Y%m%d)
```

---

## 10. Troubleshooting

### 10.1 Pods en état CrashLoopBackOff

```bash
# Vérifier les logs
kubectl logs -f pod-name -n smarthome

# Vérifier les événements
kubectl describe pod pod-name -n smarthome
```

### 10.2 Services non accessibles

```bash
# Vérifier les services
kubectl get svc -n smarthome

# Tester la connectivité interne
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://usage-collector-service:8083/actuator/health
```

### 10.3 Problèmes de ressources

```bash
# Vérifier l'utilisation des ressources
kubectl top pods -n smarthome
kubectl top nodes
```

---

## 📚 Ressources supplémentaires

- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Prometheus](https://prometheus.io/docs/)
- [Documentation Grafana](https://grafana.com/docs/)
- [Documentation Keycloak](https://www.keycloak.org/documentation)
- [Documentation NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)

---

## ✅ Checklist d'intégration

- [ ] Kubernetes cluster configuré
- [ ] Manifests Kubernetes créés
- [ ] Pipeline CI/CD configuré
- [ ] Bases de données déployées (PostgreSQL, MongoDB, Cassandra)
- [ ] API Gateway configuré (NGINX ou Kong)
- [ ] Keycloak déployé et configuré
- [ ] Prometheus et Grafana déployés
- [ ] Elastic Stack déployé
- [ ] Ingress configuré
- [ ] Secrets et ConfigMaps créés
- [ ] Health checks configurés
- [ ] Monitoring et alerting opérationnels
- [ ] Backup des bases de données configuré

