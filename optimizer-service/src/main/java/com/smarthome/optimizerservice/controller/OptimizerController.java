package com.smarthome.optimizerservice.controller;

import com.smarthome.optimizerservice.service.OptimizerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/optimizer")
@RequiredArgsConstructor
public class OptimizerController {

    private final OptimizerService optimizerService;

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "optimizer-service");
        response.put("message", "Service opérationnel et prêt à recevoir les alertes");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "optimizer-service");
        response.put("description", "Service d'optimisation de la consommation énergétique");
        response.put("functionality", "Écoute les alertes de pic et envoie des commandes aux appareils");
        response.put("listeningQueue", "peak.alerts.queue");
        response.put("sendingExchange", "control.commands.exchange");
        return ResponseEntity.ok(response);
    }

    //  NEW endpoint: logs buffer
    @GetMapping("/logs")
    public ResponseEntity<List<String>> logs(@RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(optimizerService.getRecentLogs(limit));
    }
}
