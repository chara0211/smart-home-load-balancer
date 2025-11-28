package com.smarthome.usagecollectorservice.controller;

import com.smarthome.usagecollectorservice.model.HomeUsage;
import com.smarthome.usagecollectorservice.repository.HomeUsageRepository;
import com.smarthome.usagecollectorservice.service.UsageAggregationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/usage")
@RequiredArgsConstructor
public class UsageController {
    
    private final UsageAggregationService usageAggregationService;
    private final HomeUsageRepository homeUsageRepository;
    
    @GetMapping("/current")
    public ResponseEntity<Map<String, Object>> getCurrentUsage() {
        Map<String, Object> response = new HashMap<>();
        response.put("totalPowerKw", usageAggregationService.getCurrentTotalPowerKw());
        response.put("deviceCount", usageAggregationService.getLastDevicePower().size());
        response.put("devices", usageAggregationService.getLastDevicePower());
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/history")
    public ResponseEntity<List<HomeUsage>> getUsageHistory(
            @RequestParam(required = false, defaultValue = "100") int limit) {
        List<HomeUsage> history = homeUsageRepository.findAll(
                org.springframework.data.domain.Sort.by("timestamp").descending())
                .stream()
                .limit(limit)
                .toList();
        return ResponseEntity.ok(history);
    }
    
    @GetMapping("/devices")
    public ResponseEntity<Map<String, Double>> getDeviceUsage() {
        return ResponseEntity.ok(usageAggregationService.getLastDevicePower());
    }
    
    @PostMapping("/save")
    public ResponseEntity<Map<String, Object>> saveSnapshot() {
        usageAggregationService.saveCurrentSnapshot();
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Snapshot sauvegardé avec succès");
        response.put("totalPowerKw", usageAggregationService.getCurrentTotalPowerKw());
        return ResponseEntity.ok(response);
    }
}
