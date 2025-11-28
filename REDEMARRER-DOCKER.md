# 🔄 Instructions pour redémarrer Docker Desktop

## ⚠️ Problème actuel

Docker Desktop a un problème avec son système de fichiers (`read-only file system`). Il faut le redémarrer complètement.

## 📋 Étapes à suivre

### Étape 1 : Arrêter Docker Desktop complètement

1. **Clic droit sur l'icône Docker** dans la barre des tâches (en bas à droite)
2. Cliquez sur **"Quit Docker Desktop"**
3. **Attendez 15-20 secondes** pour que Docker se ferme complètement

### Étape 2 : Vérifier que Docker est bien arrêté

Ouvrez PowerShell et exécutez :
```powershell
docker ps
```

Si vous voyez une erreur comme "Cannot connect to the Docker daemon", c'est bon signe - Docker est arrêté.

### Étape 3 : Redémarrer Docker Desktop en tant qu'administrateur

1. **Recherchez "Docker Desktop"** dans le menu Démarrer
2. **Clic droit** sur "Docker Desktop"
3. Sélectionnez **"Exécuter en tant qu'administrateur"**
4. **Attendez** que Docker Desktop démarre complètement (l'icône dans la barre des tâches doit être stable, pas animée)

### Étape 4 : Vérifier que Docker fonctionne

Dans PowerShell :
```powershell
docker ps
docker info
```

Ces commandes doivent fonctionner sans erreur.

### Étape 5 : Relancer docker-compose

```powershell
cd D:\Salma\smart-home-load-balancer
docker-compose up -d
```

## 🔧 Si ça ne fonctionne toujours pas

### Option A : Réinitialiser Docker Desktop

1. Ouvrez Docker Desktop
2. Cliquez sur l'icône ⚙️ (Settings)
3. Allez dans **Troubleshoot**
4. Cliquez sur **"Clean / Purge data"**
5. Sélectionnez **"Reset to factory defaults"**
6. Redémarrez Docker Desktop

⚠️ **Attention** : Cela supprimera toutes vos images et conteneurs !

### Option B : Redémarrer l'ordinateur

Parfois, un simple redémarrage de Windows résout le problème.

### Option C : Utiliser les services localement (temporaire)

En attendant, vous pouvez lancer les services sans Docker :

1. **PostgreSQL** : Utilisez votre installation locale
2. **RabbitMQ** : Utilisez votre installation locale ou Docker (si ça fonctionne)
3. **Usage Collector Service** : `mvn spring-boot:run` dans le dossier du service

## ✅ Après le redémarrage

Une fois Docker redémarré, vous devriez pouvoir :

```powershell
# Lancer tous les services
docker-compose up -d

# Vérifier qu'ils sont en cours d'exécution
docker-compose ps

# Voir les logs
docker-compose logs -f
```

