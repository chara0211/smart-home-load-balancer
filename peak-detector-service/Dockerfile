# ===== STAGE 1 : Maven build =====
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn -q dependency:go-offline

# Copy source code and build the JAR
COPY src ./src
RUN mvn -q -DskipTests package

# ===== STAGE 2 : Runtime image =====
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy the built jar from the previous stage
COPY --from=build /app/target/*.jar app.jar

# Expose application port inside the container
EXPOSE 8084

# Use docker profile (application-docker.properties)
ENV SPRING_PROFILES_ACTIVE=docker

ENTRYPOINT ["java", "-jar", "app.jar"]
