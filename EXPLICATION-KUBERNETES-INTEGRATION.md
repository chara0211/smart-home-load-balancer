# Explication : Intégration de Kubernetes dans ce Projet

Ce document explique **pourquoi** Kubernetes doit être intégré, **quel est son rôle**, et **comment** l'intégrer dans le projet Smart Home Load Balancer, **sans modifier le code existant**.

---

## 🎯 Pourquoi Kubernetes est Nécessaire ?

### Limitations Actuelles avec Docker Compose

Actuellement, le projet utilise Docker Compose pour orchestrer les services :

```7:24:docker-compose.yml
  postgres:
    image: postgres:16
    container_name: smart-home-load-balancer-postgres
    environment:
      POSTGRES_DB: smarthome
      POSTGRES_USER: smarthome
      POSTGRES_PASSWORD: smarthome
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U smarthome"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - smart-home-load-balancer-network
```

**Problèmes avec Docker Compose :**

1. **Pas de scaling automatique** : Un seul conteneur par service
2. **Pas de haute disponibilité** : Si un conteneur crash, il faut le redémarrer manuellement
3. **Gestion manuelle des ressources** : Pas de contrôle fin sur CPU/mémoire
4. **Pas de load balancing intégré** : Un seul point d'entrée par service
5. **Déploiement limité** : Difficile de faire du rolling update
6. **Pas de gestion des secrets** : Mots de passe en clair dans les fichiers
7. **Limité à une seule machine** : Pas de distribution sur plusieurs serveurs

### Architecture Actuelle (Docker Compose)

```
┌─────────────────────────────────────────┐
│         Machine Unique                   │
│                                         │
│  ┌──────────┐  ┌──────────┐           │
│  │ Postgres │  │ RabbitMQ │           │
│  └──────────┘  └──────────┘           │
│                                         │
│  ┌──────────┐  ┌──────────┐           │
│  │ Usage    │  │ Peak     │           │
│  │ Collector│  │ Detector │           │
│  └──────────┘  └──────────┘           │
│                                         │
│  ┌──────────┐  ┌──────────┐           │
│  │ Device   │  │ Optimizer│           │
│  │ Simulator│  │          │           │
│  └──────────┘  └──────────┘           │
└─────────────────────────────────────────┘
```

**Problème** : Tout est sur une seule machine, pas de résilience, pas de scaling.

---

## 🚀 Rôle de Kubernetes dans ce Projet

Kubernetes devient **l'orchestrateur principal** qui gère :

### 1. **Orchestration et Gestion du Cycle de Vie**

Kubernetes gère automatiquement :
- Le démarrage des pods (conteneurs)
- Le redémarrage en cas de crash
- La distribution sur plusieurs nœuds
- La gestion des dépendances entre services

**Exemple concret** : Si `usage-collector-service` crash, Kubernetes le redémarre automatiquement sans intervention manuelle.

### 2. **Scaling Automatique (Auto-scaling)**

Avec Kubernetes, vous pouvez avoir **plusieurs instances** d'un même service qui fonctionnent en parallèle :

```9:12:k8s/services/usage-collector/deployment.yaml
  replicas: 2
  selector:
    matchLabels:
      app: usage-collector-service
```

**Avantage** : Si la charge augmente, Kubernetes peut automatiquement créer plus de pods :

```11:19:k8s/services/usage-collector/hpa.yaml
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Scénario réel** :
- **Charge normale** : 2 instances de `usage-collector-service`
- **Pic de trafic** : Kubernetes détecte que le CPU dépasse 70% et crée automatiquement jusqu'à 10 instances
- **Retour à la normale** : Kubernetes réduit progressivement le nombre d'instances

### 3. **Load Balancing et Service Discovery**

Kubernetes crée automatiquement un **Service** qui fait office de load balancer :

```1:15:k8s/services/usage-collector/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: usage-collector-service
  namespace: smarthome
  labels:
    app: usage-collector-service
spec:
  type: ClusterIP
  ports:
  - port: 8083
    targetPort: 8083
    protocol: TCP
    name: http
  selector:
    app: usage-collector-service
```

**Fonctionnement** :
- Les autres services appellent `http://usage-collector-service:8083`
- Kubernetes route automatiquement les requêtes vers un pod disponible
- Si un pod est en panne, Kubernetes ne lui envoie plus de requêtes

### 4. **Gestion des Ressources (CPU/Mémoire)**

Kubernetes permet de définir des **limites de ressources** pour chaque service :

```58:64:k8s/services/usage-collector/deployment.yaml
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

**Avantages** :
- **Garantie de ressources** : Chaque service a un minimum garanti
- **Protection** : Un service ne peut pas consommer toutes les ressources
- **Optimisation** : Kubernetes peut mieux planifier les pods sur les nœuds

### 5. **Health Checks et Auto-récupération**

Kubernetes vérifie automatiquement la santé des pods :

```65:83:k8s/services/usage-collector/deployment.yaml
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8083
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8083
          initialDelaySeconds: 30
          periodSeconds: 5
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8083
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
```

**Fonctionnement** :
- **Liveness Probe** : Si le pod ne répond plus, Kubernetes le redémarre
- **Readiness Probe** : Si le pod n'est pas prêt, Kubernetes ne lui envoie pas de trafic
- **Startup Probe** : Attend que le service soit complètement démarré

### 6. **Gestion des Secrets et Configuration**

Kubernetes gère les secrets de manière sécurisée :

```34:43:k8s/services/usage-collector/deployment.yaml
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
```

**Avantage** : Les mots de passe ne sont plus en clair dans les fichiers de configuration.

### 7. **Rolling Updates (Mises à jour sans interruption)**

Kubernetes permet de mettre à jour un service **sans interruption** :

```bash
# Mise à jour de l'image
kubectl set image deployment/usage-collector-service \
  usage-collector-service=salmaidoufkir/usage-collector-service:v2.0 \
  -n smarthome

# Kubernetes fait automatiquement :
# 1. Crée un nouveau pod avec la nouvelle version
# 2. Attend qu'il soit prêt (readiness probe)
# 3. Redirige le trafic vers le nouveau pod
# 4. Supprime l'ancien pod
# → Zéro downtime !
```

---

## 🏗️ Architecture avec Kubernetes

### Architecture Distribuée

```
┌─────────────────────────────────────────────────────────────┐
│                    Cluster Kubernetes                       │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Node 1     │  │   Node 2     │  │   Node 3     │   │
│  │              │  │              │  │              │   │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │
│  │ │ Postgres │ │  │ │ Usage    │ │  │ │ Peak     │ │   │
│  │ │ (1 pod)  │ │  │ │ Collector│ │  │ │ Detector │ │   │
│  │ └──────────┘ │  │ │ (2 pods)  │ │  │ │ (2 pods) │ │   │
│  │              │  │ └──────────┘ │  │ └──────────┘ │   │
│  │ ┌──────────┐ │  │              │  │              │   │
│  │ │ RabbitMQ │ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │
│  │ │ (1 pod)  │ │  │ │ Device   │ │  │ │ Optimizer│ │   │
│  │ └──────────┘ │  │ │ Simulator│ │  │ │ (2 pods) │ │   │
│  │              │  │ │ (1 pod)  │ │  │ └──────────┘ │   │
│  └──────────────┘  │ └──────────┘ │  └──────────────┘   │
│                    └──────────────┘                      │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         API Gateway (NGINX) - Load Balancer         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Avantages** :
- **Haute disponibilité** : Si un nœud tombe, les pods sont redémarrés sur d'autres nœuds
- **Distribution de charge** : Les pods sont répartis sur plusieurs machines
- **Scaling horizontal** : Ajouter des nœuds = plus de capacité

---

## 🔄 Comment Kubernetes s'Intègre dans ce Projet

### Étape 1 : Migration Progressive

Kubernetes peut coexister avec Docker Compose :

- **Développement local** : Continuer à utiliser Docker Compose
- **Production** : Utiliser Kubernetes

### Étape 2 : Structure des Manifests Kubernetes

Les fichiers de configuration Kubernetes sont organisés ainsi :

```
k8s/
├── namespaces/          # Isolation des ressources
├── secrets/             # Gestion sécurisée des mots de passe
├── configmaps/          # Configuration centralisée
├── databases/           # PostgreSQL, MongoDB, Cassandra
├── message-broker/      # RabbitMQ
├── services/            # Les 4 microservices
│   ├── usage-collector/
│   │   ├── deployment.yaml    # Définit les pods
│   │   ├── service.yaml       # Load balancer interne
│   │   └── hpa.yaml           # Auto-scaling
│   ├── peak-detector/
│   ├── device-simulator/
│   └── optimizer/
├── api-gateway/         # NGINX pour exposer les services
├── keycloak/            # Authentification
├── monitoring/          # Prometheus, Grafana, Elastic
└── ingress/             # Point d'entrée externe
```

### Étape 3 : Déploiement

Le déploiement se fait via des commandes `kubectl` :

```bash
# 1. Créer le namespace
kubectl apply -f k8s/namespaces/

# 2. Créer les secrets
kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=smarthome \
  -n smarthome

# 3. Déployer les bases de données
kubectl apply -f k8s/databases/

# 4. Déployer les services
kubectl apply -f k8s/services/

# 5. Vérifier
kubectl get pods -n smarthome
```

---

## 📊 Comparaison : Docker Compose vs Kubernetes

| Fonctionnalité | Docker Compose | Kubernetes |
|----------------|----------------|------------|
| **Scaling** | Manuel, 1 instance | Automatique, plusieurs instances |
| **Haute disponibilité** | ❌ Non | ✅ Oui (redémarrage auto) |
| **Load balancing** | ❌ Non | ✅ Oui (Service) |
| **Gestion des ressources** | ❌ Limité | ✅ Oui (CPU/mémoire) |
| **Health checks** | ✅ Basique | ✅ Avancé (3 types) |
| **Rolling updates** | ❌ Non | ✅ Oui (zéro downtime) |
| **Secrets management** | ❌ En clair | ✅ Sécurisé |
| **Multi-nœuds** | ❌ Non | ✅ Oui |
| **Auto-scaling** | ❌ Non | ✅ Oui (HPA) |
| **Service discovery** | ✅ Via nom de service | ✅ Via DNS interne |
| **Complexité** | ⭐ Simple | ⭐⭐⭐ Plus complexe |
| **Cas d'usage** | Développement | Production |

---

## 🎯 Rôle Spécifique de Kubernetes dans ce Projet

### 1. **Gestion de la Charge de Trafic**

**Problème** : Le projet gère la consommation énergétique d'une maison intelligente. Les pics de consommation peuvent surcharger les services.

**Solution Kubernetes** :
- **Auto-scaling** : Si `usage-collector-service` reçoit trop de requêtes, Kubernetes crée automatiquement plus d'instances
- **Load balancing** : Les requêtes sont distribuées équitablement entre les instances

**Exemple concret** :
```
Pic de consommation détecté → Plus de requêtes vers usage-collector-service
→ CPU dépasse 70% → Kubernetes crée 2 nouvelles instances
→ Charge répartie sur 4 instances → Service reste réactif
```

### 2. **Résilience et Disponibilité**

**Problème** : Si un service crash, toute l'application peut être affectée.

**Solution Kubernetes** :
- **Auto-restart** : Si `peak-detector-service` crash, Kubernetes le redémarre automatiquement
- **Health checks** : Kubernetes vérifie en permanence que les services sont sains
- **Multi-instances** : Même si un pod crash, les autres continuent de fonctionner

**Exemple concret** :
```
Pod de peak-detector-service crash
→ Kubernetes détecte via liveness probe
→ Redémarre automatiquement le pod
→ Service reste disponible (les autres pods continuent)
```

### 3. **Gestion des Dépendances**

**Problème** : Les services ont des dépendances (PostgreSQL, RabbitMQ).

**Solution Kubernetes** :
- **Readiness probes** : Un service ne reçoit du trafic que quand ses dépendances sont prêtes
- **Init containers** : Peuvent attendre que PostgreSQL soit prêt avant de démarrer

**Exemple concret** :
```
usage-collector-service démarre
→ Readiness probe échoue (PostgreSQL pas encore prêt)
→ Kubernetes n'envoie pas de trafic au service
→ PostgreSQL devient prêt
→ Readiness probe réussit
→ Kubernetes commence à envoyer du trafic
```

### 4. **Mises à jour sans Interruption**

**Problème** : Mettre à jour un service nécessite de l'arrêter, causant une interruption.

**Solution Kubernetes** :
- **Rolling updates** : Mise à jour progressive, pod par pod
- **Zéro downtime** : Les utilisateurs ne voient pas d'interruption

**Exemple concret** :
```
Nouvelle version de usage-collector-service disponible
→ Kubernetes crée un nouveau pod avec la nouvelle version
→ Attend qu'il soit prêt (readiness probe)
→ Redirige le trafic vers le nouveau pod
→ Supprime l'ancien pod
→ Mise à jour terminée sans interruption
```

### 5. **Monitoring et Observabilité**

**Problème** : Difficile de surveiller tous les services manuellement.

**Solution Kubernetes** :
- **Annotations Prometheus** : Les pods exposent automatiquement leurs métriques
- **Service discovery** : Prometheus découvre automatiquement tous les services à monitorer

```17:20:k8s/services/usage-collector/deployment.yaml
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8083"
        prometheus.io/path: "/actuator/prometheus"
```

---

## 🔧 Intégration sans Modifier le Code

### Principe

Kubernetes s'intègre **sans modifier le code Java** grâce à :

1. **Variables d'environnement** : La configuration se fait via des variables d'environnement injectées par Kubernetes
2. **Service Discovery** : Les services se trouvent via les noms de services Kubernetes (DNS interne)
3. **Health endpoints** : Spring Boot Actuator expose déjà les endpoints nécessaires (`/actuator/health`)

### Exemple : Configuration PostgreSQL

**Docker Compose** :
```yaml
environment:
  SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/smarthome
```

**Kubernetes** :
```yaml
env:
- name: SPRING_DATASOURCE_URL
  value: "jdbc:postgresql://postgres-service:5432/smarthome"
```

**Code Java** : **Aucun changement** ! Le code lit toujours `spring.datasource.url` depuis les variables d'environnement.

### Exemple : Service Discovery

**Docker Compose** :
- Les services se trouvent via le nom du service : `postgres`, `rabbitmq`

**Kubernetes** :
- Les services se trouvent via le nom du Service Kubernetes : `postgres-service`, `rabbitmq-service`

**Code Java** : **Aucun changement** ! Le code utilise toujours les noms de services pour se connecter.

---

## 📈 Avantages Concrets pour ce Projet

### 1. **Scalabilité pour les Pics de Consommation**

Quand la consommation énergétique augmente :
- Plus de requêtes vers `usage-collector-service`
- Kubernetes scale automatiquement de 2 à 10 instances
- Le service reste réactif même sous charge

### 2. **Haute Disponibilité 24/7**

Pour une maison intelligente, les services doivent être disponibles en permanence :
- Si un pod crash, Kubernetes le redémarre automatiquement
- Plusieurs instances garantissent la continuité même en cas de panne

### 3. **Mises à jour sans Interruption**

Mettre à jour les services sans affecter les utilisateurs :
- Rolling updates permettent de déployer de nouvelles versions
- Les utilisateurs ne voient aucune interruption

### 4. **Gestion Centralisée**

Tous les services sont gérés depuis un seul endroit :
- `kubectl get pods -n smarthome` : Voir tous les services
- `kubectl logs -f deployment/usage-collector-service` : Voir les logs
- `kubectl describe pod <pod-name>` : Diagnostiquer les problèmes

### 5. **Sécurité Renforcée**

- Secrets gérés de manière sécurisée (pas en clair)
- Isolation via les namespaces
- Contrôle d'accès via RBAC

---

## 🚀 Conclusion

Kubernetes transforme ce projet d'une **application monolithique conteneurisée** en une **architecture microservices distribuée et scalable** :

- ✅ **Scalabilité automatique** pour gérer les pics de charge
- ✅ **Haute disponibilité** pour un service 24/7
- ✅ **Résilience** avec auto-restart et health checks
- ✅ **Mises à jour sans interruption** avec rolling updates
- ✅ **Gestion centralisée** de tous les services
- ✅ **Sécurité** avec gestion des secrets
- ✅ **Observabilité** avec intégration Prometheus

**Sans modifier une ligne de code Java**, Kubernetes apporte toutes ces capacités en orchestrant les conteneurs existants de manière plus intelligente et robuste.

---

## 📚 Prochaines Étapes

1. **Créer les secrets Kubernetes** (voir `k8s/secrets/README.md`)
2. **Déployer sur un cluster Kubernetes** (local avec Minikube/Kind ou cloud)
3. **Configurer l'auto-scaling** selon vos besoins
4. **Mettre en place le monitoring** avec Prometheus/Grafana
5. **Configurer l'API Gateway** pour exposer les services

Tous les fichiers de configuration Kubernetes sont déjà prêts dans le dossier `k8s/` !

