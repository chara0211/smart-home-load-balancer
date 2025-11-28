# Guide Docker Compose - Smart Home Load Balancer

Ce guide explique comment utiliser Docker Compose pour lancer tous les services du projet Smart Home Load Balancer.

## 📋 Prérequis

- Docker Desktop installé et en cours d'exécution
- Docker Compose (inclus avec Docker Desktop)

## 🚀 Démarrage rapide

### 1. Lancer tous les services

```bash
docker-compose up -d
```

Cette commande va :
- Créer et démarrer PostgreSQL
- Créer et démarrer RabbitMQ
- Construire et démarrer usage-collector-service
- Créer un réseau Docker pour la communication entre services

### 2. Vérifier que tous les services sont en cours d'exécution

```bash
docker-compose ps
```

Vous devriez voir :
- `smart-home-postgres` (PostgreSQL)
- `smart-home-rabbitmq` (RabbitMQ)
- `smart-home-usage-collector` (Usage Collector Service)

### 3. Voir les logs

```bash
# Tous les services
docker-compose logs -f

# Un service spécifique
docker-compose logs -f usage-collector-service
```

## 🛠️ Commandes utiles

### Arrêter tous les services

```bash
docker-compose down
```

### Arrêter et supprimer les volumes (⚠️ supprime les données)

```bash
docker-compose down -v
```

### Reconstruire un service après modification

```bash
docker-compose build usage-collector-service
docker-compose up -d usage-collector-service
```

### Redémarrer un service

```bash
docker-compose restart usage-collector-service
```

## 🌐 Accès aux services

### Usage Collector Service
- **URL** : http://localhost:8082
- **Endpoints** :
  - `GET /usage/current` - Consommation actuelle
  - `GET /usage/history` - Historique
  - `GET /usage/devices` - État des appareils
  - `POST /usage/save` - Sauvegarder un snapshot

### RabbitMQ Management Interface
- **URL** : http://localhost:15672
- **Username** : `guest`
- **Password** : `guest`

### PostgreSQL
- **Host** : `localhost`
- **Port** : `5432`
- **Database** : `smarthome`
- **Username** : `smarthome`
- **Password** : `smarthome`

## 📁 Structure des services

```
smart-home-load-balancer/
├── docker-compose.yml          # Configuration Docker Compose
├── usage-collector-service/
│   ├── Dockerfile              # Image Docker du service
│   └── src/main/resources/
│       └── application-docker.properties  # Config pour Docker
└── [autres-services-futurs]/
```

## 🔧 Configuration

### Variables d'environnement

Les services utilisent les configurations suivantes :

- **PostgreSQL** : Défini dans `docker-compose.yml`
- **RabbitMQ** : Défini dans `docker-compose.yml`
- **Usage Collector Service** : Utilise le profil `docker` qui charge `application-docker.properties`

### Ajouter un nouveau service

1. Créer le dossier du service (ex: `device-service/`)
2. Créer un `Dockerfile` dans ce dossier
3. Ajouter le service dans `docker-compose.yml` :

```yaml
device-service:
  build:
    context: ./device-service
    dockerfile: Dockerfile
  container_name: smart-home-device-service
  ports:
    - "8081:8081"
  depends_on:
    - rabbitmq
    - postgres
  networks:
    - smart-home-network
```

## 🐛 Dépannage

### Le service ne démarre pas

1. Vérifier les logs : `docker-compose logs usage-collector-service`
2. Vérifier que les dépendances sont démarrées : `docker-compose ps`
3. Vérifier les healthchecks : `docker-compose ps` (colonne STATUS)

### Erreur de connexion à PostgreSQL

- Vérifier que PostgreSQL est démarré : `docker-compose ps postgres`
- Vérifier les logs : `docker-compose logs postgres`
- Attendre que le healthcheck soit OK avant de démarrer les services

### Erreur de connexion à RabbitMQ

- Vérifier que RabbitMQ est démarré : `docker-compose ps rabbitmq`
- Vérifier les logs : `docker-compose logs rabbitmq`
- Accéder à l'interface web : http://localhost:15672

### Reconstruire complètement

```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

## 📝 Notes

- Les données PostgreSQL sont persistées dans le volume `postgres_data`
- Les données RabbitMQ sont persistées dans le volume `rabbitmq_data`
- Les services communiquent via le réseau Docker `smart-home-network`
- Les noms de services Docker sont utilisés pour la communication interne (ex: `postgres`, `rabbitmq`)

