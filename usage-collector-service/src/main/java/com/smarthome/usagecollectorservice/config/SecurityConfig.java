package com.smarthome.usagecollectorservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // ⚠️ IMPORTANT : Exclure TOUS les endpoints Actuator de la sécurité
                // pour permettre les health checks Kubernetes
                .requestMatchers("/actuator/**").permitAll()
                // ⚠️ IMPORTANT : Permettre l'accès à /usage/current pour les services internes
                // (peak-detector-service a besoin d'accéder à ces données)
                .requestMatchers("/usage/current").permitAll()
                // Tous les autres endpoints nécessitent une authentification
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> {})
            );
        
        return http.build();
    }
}


