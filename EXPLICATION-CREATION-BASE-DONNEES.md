# Explication : Comment la Base de Données se Crée dans ce Projet

Ce document explique le processus de création de la base de données PostgreSQL dans le projet Smart Home Load Balancer, **sans modifier le code existant**.

## 📋 Vue d'ensemble

La création de la base de données se fait en **deux étapes principales** :

1. **Création du conteneur PostgreSQL et de la base de données** (via Docker Compose)
2. **Création automatique du schéma (tables)** (via Hibernate/JPA au démarrage de l'application Spring Boot)

---

## 🐳 Étape 1 : Création du Conteneur PostgreSQL et de la Base de Données

### Configuration Docker Compose

Dans le fichier `docker-compose.yml`, le service PostgreSQL est configuré ainsi :

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

### Processus de création

Quand vous exécutez `docker-compose up`, voici ce qui se passe :

1. **Démarrage du conteneur PostgreSQL** :
   - Docker télécharge l'image `postgres:16` si nécessaire
   - Un nouveau conteneur est créé avec le nom `smart-home-load-balancer-postgres`

2. **Initialisation de PostgreSQL** :
   - Au premier démarrage, PostgreSQL s'initialise automatiquement
   - La variable d'environnement `POSTGRES_DB: smarthome` indique à PostgreSQL de **créer automatiquement une base de données nommée `smarthome`**
   - La variable `POSTGRES_USER: smarthome` crée un utilisateur avec ce nom
   - La variable `POSTGRES_PASSWORD: smarthome` définit le mot de passe de cet utilisateur

3. **Persistance des données** :
   - Le volume `postgres_data` est créé pour stocker les données de manière persistante
   - Les données sont stockées dans `/var/lib/postgresql/data` à l'intérieur du conteneur
   - Même si le conteneur est arrêté, les données restent dans le volume Docker

**Résultat** : Une base de données PostgreSQL nommée `smarthome` est créée et prête à être utilisée.

---

## 🔄 Étape 2 : Création Automatique du Schéma (Tables) par Hibernate

### Configuration Spring Boot

Dans les fichiers de configuration Spring Boot, on trouve cette configuration cruciale :

```8:10:usage-collector-service/src/main/resources/application-docker.properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

### Explication de `spring.jpa.hibernate.ddl-auto=update`

Cette propriété indique à Hibernate (l'ORM de Spring Boot) comment gérer le schéma de la base de données :

- **`update`** : Hibernate **compare** les entités JPA avec le schéma existant dans la base de données
  - Si une table n'existe pas → **elle est créée automatiquement**
  - Si une colonne manque → **elle est ajoutée automatiquement**
  - Si une colonne existe mais n'est plus dans l'entité → **elle n'est PAS supprimée** (sécurité)
  - Les données existantes sont **préservées**

### L'entité JPA qui définit le schéma

Dans le code, il existe une entité JPA qui définit la structure de la table :

```10:25:usage-collector-service/src/main/java/com/smarthome/usagecollectorservice/model/HomeUsage.java
@Entity
@Table(name = "home_usage")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HomeUsage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "total_power_kw", nullable = false)
    private double totalPowerKw;
    
    @Column(name = "timestamp", nullable = false)
    private Instant timestamp;
}
```

### Processus de création des tables

Quand l'application Spring Boot démarre (`usage-collector-service`), voici ce qui se passe :

1. **Connexion à la base de données** :
   - Spring Boot se connecte à PostgreSQL via l'URL : `jdbc:postgresql://postgres:5432/smarthome`
   - Les identifiants sont : `smarthome` / `smarthome`

2. **Scan des entités JPA** :
   - Spring Boot scanne le package `com.smarthome.usagecollectorservice.model`
   - Il trouve l'entité `HomeUsage` annotée avec `@Entity`

3. **Analyse du schéma** :
   - Hibernate analyse les annotations de l'entité :
     - `@Table(name = "home_usage")` → nom de la table : `home_usage`
     - `@Id @GeneratedValue` → colonne `id` de type BIGSERIAL (auto-incrémenté)
     - `@Column(name = "total_power_kw", nullable = false)` → colonne `total_power_kw` de type DOUBLE PRECISION, NOT NULL
     - `@Column(name = "timestamp", nullable = false)` → colonne `timestamp` de type TIMESTAMP, NOT NULL

4. **Création automatique de la table** :
   - Hibernate génère et exécute automatiquement cette requête SQL (équivalent) :
   ```sql
   CREATE TABLE IF NOT EXISTS home_usage (
       id BIGSERIAL PRIMARY KEY,
       total_power_kw DOUBLE PRECISION NOT NULL,
       timestamp TIMESTAMP NOT NULL
   );
   ```

5. **Logs SQL** :
   - Grâce à `spring.jpa.show-sql=true`, vous pouvez voir les requêtes SQL dans les logs
   - Grâce à `spring.jpa.properties.hibernate.format_sql=true`, les requêtes sont formatées de manière lisible

**Résultat** : La table `home_usage` est créée automatiquement dans la base de données `smarthome`.

---

## 🔍 Résumé du Flux Complet

```
1. docker-compose up
   ↓
2. Conteneur PostgreSQL démarre
   ↓
3. PostgreSQL crée automatiquement la base de données "smarthome"
   ↓
4. Application Spring Boot démarre
   ↓
5. Spring Boot se connecte à PostgreSQL
   ↓
6. Hibernate scanne les entités JPA (@Entity)
   ↓
7. Hibernate compare le schéma avec la base de données
   ↓
8. Hibernate crée automatiquement les tables manquantes
   ↓
9. ✅ Base de données prête à être utilisée
```

---

## 📊 Structure Finale de la Base de Données

Après le démarrage complet, la base de données `smarthome` contient :

### Table : `home_usage`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY, AUTO_INCREMENT |
| `total_power_kw` | DOUBLE PRECISION | NOT NULL |
| `timestamp` | TIMESTAMP | NOT NULL |

---

## 🔧 Points Importants

### 1. Mode `update` vs autres modes

- **`update`** (utilisé ici) : Crée/modifie les tables, ne supprime jamais
- **`create`** : Recrée toutes les tables à chaque démarrage (⚠️ supprime les données)
- **`create-drop`** : Crée au démarrage, supprime à l'arrêt (⚠️ supprime les données)
- **`validate`** : Vérifie seulement que le schéma correspond (ne modifie rien)
- **`none`** : Désactive la gestion automatique du schéma

### 2. Persistance des données

- Les données sont **persistantes** grâce au volume Docker `postgres_data`
- Même si vous arrêtez les conteneurs avec `docker-compose down`, les données restent
- Pour supprimer les données : `docker-compose down -v` (supprime aussi les volumes)

### 3. Environnements différents

Le projet utilise deux fichiers de configuration :

- **`application.properties`** : Pour le développement local (connexion à `localhost:5432`)
- **`application-docker.properties`** : Pour Docker (connexion à `postgres:5432`, nom du service Docker)

Le profil `docker` est activé dans `docker-compose.yml` :
```yaml
environment:
  SPRING_PROFILES_ACTIVE: docker
```

---

## 🧪 Vérification

Pour vérifier que tout fonctionne :

1. **Vérifier que PostgreSQL est démarré** :
   ```bash
   docker-compose ps postgres
   ```

2. **Se connecter à la base de données** :
   ```bash
   docker exec -it smart-home-load-balancer-postgres psql -U smarthome -d smarthome
   ```

3. **Lister les tables** :
   ```sql
   \dt
   ```

4. **Voir la structure de la table** :
   ```sql
   \d home_usage
   ```

5. **Voir les données** :
   ```sql
   SELECT * FROM home_usage;
   ```

---

## 📝 Conclusion

La création de la base de données dans ce projet est **entièrement automatique** :

- ✅ **Base de données** : Créée automatiquement par PostgreSQL via Docker Compose
- ✅ **Tables** : Créées automatiquement par Hibernate au démarrage de l'application
- ✅ **Aucun script SQL manuel** : Tout est géré par la configuration

Cette approche est idéale pour le développement car elle permet de démarrer rapidement sans configuration manuelle, tout en préservant les données grâce aux volumes Docker.

