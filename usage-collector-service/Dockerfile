# Dockerfile pour usage-collector-service
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copier le fichier pom.xml
COPY pom.xml .

# Télécharger les dépendances (cache layer)
RUN mvn dependency:go-offline -B

# Copier le code source
COPY src ./src

# Compiler et créer le JAR
RUN mvn clean package -DskipTests

# Image finale
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copier le JAR depuis l'étape de build
COPY --from=build /app/target/*.jar app.jar

# Exposer le port
EXPOSE 8082

# Commande pour démarrer l'application
ENTRYPOINT ["java", "-jar", "app.jar"]

