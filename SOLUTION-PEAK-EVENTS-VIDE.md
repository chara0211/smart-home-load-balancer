# Solution : Peak Events Vide dans le Dashboard

## 🔴 Problème Identifié

La section "Peak Events" affiche "No peak events" car :

1. **401 Unauthorized** : `peak-detector-service` ne peut pas récupérer les données de `usage-collector-service`
2. **Pas de données de consommation** : Sans données, aucun peak ne peut être détecté
3. **Peak detection désactivée** : Le service saute les vérifications à cause de l'erreur 401

## ✅ Solution

### Option 1 : Permettre l'accès interne sans authentification (Recommandé)

Modifier `SecurityConfig.java` de `usage-collector-service` pour permettre l'accès à `/usage/current` depuis les services internes.

### Option 2 : Configurer l'authentification service-to-service

Créer un service account et configurer `RestTemplate` pour envoyer un token.

## 🔧 Correction à Appliquer

Modifier `usage-collector-service/src/main/java/com/smarthome/usagecollectorservice/config/SecurityConfig.java` :

```java
.authorizeHttpRequests(auth -> auth
    // Actuator endpoints accessibles sans authentification
    .requestMatchers("/actuator/**").permitAll()
    // ⚠️ IMPORTANT : Permettre l'accès à /usage/current pour les services internes
    .requestMatchers("/usage/current").permitAll()
    // Tous les autres endpoints nécessitent une authentification
    .anyRequest().authenticated()
)
```

## 📝 Explication

Le `peak-detector-service` appelle `usage-collector-service` toutes les 5 secondes pour vérifier la consommation. Si l'appel échoue avec 401, aucune détection de peak n'est possible.

En permettant l'accès à `/usage/current` sans authentification, les services internes peuvent récupérer les données nécessaires.

## ✅ Résultat Attendu

- ✅ `peak-detector-service` peut récupérer les données de consommation
- ✅ Les peaks sont détectés et stockés
- ✅ La section "Peak Events" affiche les événements détectés

