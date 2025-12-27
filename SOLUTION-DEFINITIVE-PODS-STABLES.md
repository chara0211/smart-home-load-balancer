# Solution Définitive : Pods Stables et Prêts Rapidement

## 🔴 Problème Principal

Les pods redémarrent constamment (20+ restarts) et ne deviennent jamais `Ready` car :

1. **401 Unauthorized sur `/actuator/health`** : Spring Security bloque les health checks
2. **Services prennent 3-4 minutes à démarrer** : Les probes attendent seulement 30-60 secondes
3. **Pods tués trop tôt** : Les liveness probes tuent les pods avant qu'ils soient prêts

## ✅ Solution Complète

### 1. Désactiver Spring Security pour Actuator

Le problème est que Spring Security s'applique **avant** que les endpoints Actuator soient configurés. Il faut exclure Actuator de la chaîne de sécurité.

**Modifier `SecurityConfig.java` dans tous les services** :

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // ⚠️ IMPORTANT : Exclure Actuator AVANT toute autre configuration
                .requestMatchers("/actuator/**").permitAll()
                // Tous les autres endpoints nécessitent une authentification
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> {})
            );
        
        return http.build();
    }
}
```

### 2. Configurer Actuator pour être Accessible

Dans `application-kubernetes.properties`, s'assurer que :

```properties
# Actuator endpoints
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=when-authorized
# ⚠️ IMPORTANT : Désactiver la sécurité pour les health checks
management.endpoints.web.base-path=/actuator
management.security.enabled=false
```

### 3. Ajuster les Probes Kubernetes

Les services Spring Boot prennent **3-4 minutes** à démarrer. Les probes doivent attendre assez longtemps :

```yaml
startupProbe:
  httpGet:
    path: /actuator/health
    port: 8086
  initialDelaySeconds: 60      # Attendre 1 minute avant de commencer
  periodSeconds: 10            # Vérifier toutes les 10 secondes
  timeoutSeconds: 10            # Timeout de 10 secondes
  failureThreshold: 60          # 60 × 10s = 10 minutes max d'attente

readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8086
  initialDelaySeconds: 180      # Attendre 3 minutes après le démarrage
  periodSeconds: 10
  timeoutSeconds: 10
  failureThreshold: 10          # 10 × 10s = 100 secondes de tolérance

livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8086
  initialDelaySeconds: 300      # Attendre 5 minutes après le démarrage
  periodSeconds: 30             # Vérifier toutes les 30 secondes
  timeoutSeconds: 10
  failureThreshold: 10          # 10 × 30s = 5 minutes de tolérance
```

## 🔧 Actions à Effectuer

### Étape 1 : Corriger SecurityConfig (Tous les Services)

Modifier les fichiers suivants :
- `billing-service/src/main/java/com/smarthome/billing/config/SecurityConfig.java`
- `usage-collector-service/src/main/java/com/smarthome/usagecollectorservice/config/SecurityConfig.java`
- `peak-detector-service/src/main/java/com/smarthome/peakdetectorservice/config/SecurityConfig.java`
- `optimizer-service/src/main/java/com/smarthome/optimizerservice/config/SecurityConfig.java`
- `device-simulator-service/src/main/java/com/smarthome/devicesimulatorservice/config/SecurityConfig.java`

**Changement** : Remplacer `.requestMatchers("/actuator/health/**", ...)` par `.requestMatchers("/actuator/**").permitAll()`

### Étape 2 : Ajouter Configuration Actuator

Dans tous les fichiers `application-kubernetes.properties`, ajouter :

```properties
management.security.enabled=false
```

### Étape 3 : Mettre à Jour les Deployments

Ajuster les probes dans tous les fichiers `deployment.yaml` des services Spring Boot.

### Étape 4 : Rebuild et Redéployer

```powershell
# Rebuild tous les services
.\scripts\rebuild-et-redemarrer-services.ps1

# Ou manuellement pour chaque service
cd peak-detector-service
docker build -t salmaidoufkir/peak-detector-service:latest .
docker push salmaidoufkir/peak-detector-service:latest
kubectl rollout restart deployment/peak-detector-service -n smarthome
```

## 🧪 Test

Après avoir appliqué les corrections :

```powershell
# Surveiller les pods
kubectl get pods -n smarthome -w

# Vérifier les événements (plus d'erreurs 401)
kubectl get events -n smarthome --sort-by='.lastTimestamp' | Select-Object -Last 20

# Tester un endpoint de health directement
kubectl port-forward -n smarthome svc/billing-service 8086:8086
# Dans un autre terminal : curl http://localhost:8086/actuator/health
```

## ✅ Résultat Attendu

- ✅ Les health checks retournent **200 OK** (au lieu de 401)
- ✅ Les pods démarrent en **3-4 minutes** et deviennent `Ready`
- ✅ **Pas de redémarrages constants** (restarts = 0 ou 1)
- ✅ Les services sont **stables et fonctionnels**

## 📝 Note Importante

**Pourquoi les pods prennent 3-4 minutes à démarrer ?**

Spring Boot doit :
1. Charger les dépendances (30-60s)
2. Initialiser Hibernate/JPA (30-60s)
3. Se connecter à PostgreSQL (10-20s)
4. Se connecter à RabbitMQ (10-20s)
5. Initialiser Spring Security et Keycloak (30-60s)
6. Démarrer Tomcat et les endpoints (10-20s)

**Total : 2-4 minutes** selon les ressources disponibles.

Les probes doivent donc attendre assez longtemps pour ne pas tuer les pods prématurément.

