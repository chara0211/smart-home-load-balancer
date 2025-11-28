# Dépannage Docker - Smart Home Load Balancer

## Erreur "input/output error" lors du pull d'images

### Solution 1 : Utiliser une image PostgreSQL existante

Si vous avez déjà une image PostgreSQL sur votre système, modifiez `docker-compose.yml` pour utiliser cette version :

```yaml
postgres:
  image: postgres:16  # ou postgres:latest
```

### Solution 2 : Redémarrer Docker Desktop

1. Fermez complètement Docker Desktop
2. Redémarrez Docker Desktop en tant qu'administrateur
3. Réessayez : `docker-compose up -d`

### Solution 3 : Nettoyer et réessayer

```bash
# Arrêter tous les conteneurs
docker stop $(docker ps -aq)

# Nettoyer les images non utilisées
docker image prune -a

# Réessayer
docker-compose up -d
```

### Solution 4 : Vérifier l'espace disque

L'erreur I/O peut être due à un manque d'espace disque :

```bash
# Windows PowerShell
Get-PSDrive C | Select-Object Used,Free

# Vérifier l'espace Docker
docker system df
```

### Solution 5 : Réinitialiser Docker Desktop (dernier recours)

Si rien ne fonctionne :

1. Ouvrez Docker Desktop
2. Settings → Troubleshoot → Clean / Purge data
3. Redémarrez Docker Desktop

## Erreur "read-only file system"

Cette erreur indique un problème avec Docker Desktop :

1. **Redémarrer Docker Desktop en tant qu'administrateur**
2. **Vérifier les permissions** : Assurez-vous d'avoir les droits d'administration
3. **Vérifier l'état de Docker** : `docker info`

## Alternative : Utiliser les services existants

Si vous avez déjà PostgreSQL et RabbitMQ en cours d'exécution localement, vous pouvez :

1. Commenter les services postgres et rabbitmq dans docker-compose.yml
2. Utiliser `localhost` dans application.properties au lieu de `docker`
3. Lancer uniquement le service usage-collector-service

```yaml
# Commenter ces services si déjà en cours d'exécution
# postgres:
#   ...
# rabbitmq:
#   ...
```

## Vérification de l'état

```bash
# Vérifier les conteneurs
docker ps -a

# Vérifier les images
docker images

# Vérifier les volumes
docker volume ls

# Vérifier les réseaux
docker network ls
```

