package com.smarthome.usagecollectorservice.service;

import com.smarthome.usagecollectorservice.config.RabbitConfig;
import com.smarthome.usagecollectorservice.model.DeviceUsageEvent;
import com.smarthome.usagecollectorservice.model.HomeUsage;
import com.smarthome.usagecollectorservice.repository.HomeUsageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class UsageAggregationService {
    
    private final HomeUsageRepository homeUsageRepository;
    
    // Maintient l'état courant de la puissance par appareil
    private final Map<String, Double> lastDevicePower = new ConcurrentHashMap<>();
    
    // Puissance totale courante
    private volatile double currentTotalPowerKw = 0.0;
    
    @RabbitListener(queues = RabbitConfig.DEVICE_USAGE_QUEUE)
    public void onDeviceUsage(DeviceUsageEvent event) {
        log.info("Reçu événement de consommation pour device {}: {} kW", 
                event.getDeviceId(), event.getCurrentPowerKw());
        
        // Mettre à jour la puissance de l'appareil
        lastDevicePower.put(event.getDeviceId(), event.getCurrentPowerKw());
        
        // Recalculer le total
        recalculateTotal();
        
        // Persister dans PostgreSQL
        persistHomeUsage();
    }
    
    private void recalculateTotal() {
        currentTotalPowerKw = lastDevicePower.values()
                .stream()
                .mapToDouble(Double::doubleValue)
                .sum();
        log.debug("Puissance totale recalculée: {} kW", currentTotalPowerKw);
    }
    
    private void persistHomeUsage() {
        HomeUsage homeUsage = new HomeUsage();
        homeUsage.setTotalPowerKw(currentTotalPowerKw);
        homeUsage.setTimestamp(Instant.now());
        
        homeUsageRepository.save(homeUsage);
        log.debug("Snapshot de consommation persisté: {} kW à {}", 
                currentTotalPowerKw, homeUsage.getTimestamp());
    }
    
    public double getCurrentTotalPowerKw() {
        return currentTotalPowerKw;
    }
    
    public Map<String, Double> getLastDevicePower() {
        return new ConcurrentHashMap<>(lastDevicePower);
    }
    
    public void saveCurrentSnapshot() {
        persistHomeUsage();
    }
}
