# Solution pour l'erreur "read-only file system" Docker

## 🔴 Problème

L'erreur `read-only file system` indique que Docker Desktop a un problème avec son système de fichiers interne. C'est un problème connu avec Docker Desktop sur Windows.

## ✅ Solutions

### Solution 1 : Redémarrer Docker Desktop (À ESSAYER EN PREMIER)

1. **Fermer complètement Docker Desktop**
   - Clic droit sur l'icône Docker dans la barre des tâches
   - Quit Docker Desktop
   - Attendre 10-15 secondes

2. **Redémarrer Docker Desktop en tant qu'administrateur**
   - Clic droit sur Docker Desktop
   - "Exécuter en tant qu'administrateur"

3. **Attendre que Docker soit complètement démarré** (icône stable dans la barre des tâches)

4. **Réessayer** :
   ```bash
   docker-compose up -d
   ```

### Solution 2 : Réinitialiser Docker Desktop

Si la solution 1 ne fonctionne pas :

1. Ouvrir Docker Desktop
2. Aller dans **Settings** (⚙️)
3. **Troubleshoot** → **Clean / Purge data**
4. Sélectionner **"Remove all data"** ou **"Reset to factory defaults"**
5. Redémarrer Docker Desktop

⚠️ **Attention** : Cela supprimera toutes vos images et conteneurs !

### Solution 3 : Utiliser les services sans Docker (Solution temporaire)

En attendant de résoudre le problème Docker, vous pouvez :

1. **Lancer PostgreSQL et RabbitMQ avec docker-compose** (sans le service Spring Boot) :
   ```bash
   docker-compose up -d postgres rabbitmq
   ```

2. **Lancer le service Spring Boot localement** :
   ```bash
   cd usage-collector-service
   mvn spring-boot:run
   ```

   Le service utilisera `application.properties` (avec `localhost`) au lieu de `application-docker.properties`.

### Solution 4 : Vérifier WSL2 (si vous utilisez WSL2)

Si Docker Desktop utilise WSL2 :

```bash
# Dans PowerShell (en tant qu'administrateur)
wsl --shutdown
# Redémarrer Docker Desktop
```

### Solution 5 : Réinstaller Docker Desktop (Dernier recours)

1. Désinstaller Docker Desktop complètement
2. Redémarrer l'ordinateur
3. Réinstaller Docker Desktop
4. Redémarrer l'ordinateur

## 🔧 Configuration temporaire

J'ai modifié le `docker-compose.yml` pour commenter le service `usage-collector-service`. Vous pouvez :

1. **Lancer uniquement PostgreSQL et RabbitMQ** :
   ```bash
   docker-compose up -d postgres rabbitmq
   ```

2. **Lancer le service Spring Boot localement** :
   ```bash
   cd usage-collector-service
   mvn spring-boot:run
   ```

3. **Quand Docker fonctionne à nouveau**, décommentez le service dans `docker-compose.yml` et relancez.

## 📝 Vérification

Pour vérifier que les services fonctionnent :

```bash
# Vérifier les conteneurs
docker ps

# Vérifier les logs
docker-compose logs postgres
docker-compose logs rabbitmq

# Tester la connexion PostgreSQL
docker exec -it smart-home-postgres psql -U smarthome -d smarthome

# Accéder à RabbitMQ Management
# http://localhost:15672 (guest/guest)
```

## 🎯 Recommandation

**Essayez d'abord la Solution 1** (redémarrer Docker Desktop en tant qu'administrateur). C'est la solution la plus simple et la plus courante pour ce type d'erreur.

