# Résumé : Pourquoi les Pods Redémarrent Constamment

## 🔴 Problème Identifié

Vous avez raison de vous inquiéter ! Les pods redémarrent constamment (20+ restarts) et ne deviennent jamais `Ready`, ce qui rend l'application inutilisable.

### Causes Principales

1. **401 Unauthorized sur les Health Checks**
   - Les probes Kubernetes appellent `/actuator/health`
   - Spring Security retourne 401 (non autorisé)
   - Kubernetes pense que le service est mort et le redémarre

2. **Services Prendent 3-4 Minutes à Démarrer**
   - Spring Boot doit charger les dépendances, initialiser Hibernate, se connecter à PostgreSQL et RabbitMQ
   - Les probes attendent seulement 30-60 secondes
   - Les pods sont tués avant d'être prêts

3. **Cycle Infini de Redémarrage**
   - Pod démarre → Health check échoue (401) → Pod tué → Pod redémarre → Répète...

## ✅ Solutions Appliquées

### 1. Correction SecurityConfig (Tous les Services)

**Avant** :
```java
.requestMatchers("/actuator/health/**", "/actuator/info", "/actuator/health").permitAll()
```

**Après** :
```java
.requestMatchers("/actuator/**").permitAll()
```

**Pourquoi ?** : Spring Security doit autoriser **TOUS** les endpoints Actuator, pas seulement `/health`.

### 2. Probes Ajustées (À Appliquer)

Les probes doivent attendre assez longtemps :

- **Startup** : `initialDelaySeconds: 60`, `failureThreshold: 60` (10 minutes max)
- **Readiness** : `initialDelaySeconds: 180` (3 minutes après démarrage)
- **Liveness** : `initialDelaySeconds: 300` (5 minutes après démarrage)

## 🔧 Prochaines Étapes

1. **Rebuild tous les services** avec la correction SecurityConfig
2. **Mettre à jour les deployments** avec les nouvelles probes
3. **Redéployer** et vérifier que les pods deviennent `Ready`

## 📝 Note Importante

**Pourquoi les services prennent 3-4 minutes à démarrer ?**

C'est normal pour Spring Boot avec :
- Hibernate/JPA (initialisation des entités)
- Connexions à PostgreSQL et RabbitMQ
- Spring Security et Keycloak
- Chargement des dépendances

**Les probes doivent attendre assez longtemps** pour ne pas tuer les pods prématurément.

Une fois que les pods sont `Ready`, ils restent stables et ne redémarrent plus.

