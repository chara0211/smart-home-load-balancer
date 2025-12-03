package com.smarthome.optimizerservice.service;

import com.smarthome.optimizerservice.config.RabbitConfig;
import com.smarthome.optimizerservice.model.DeviceCommand;
import com.smarthome.optimizerservice.model.PeakEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class OptimizerService {

    private final RabbitTemplate rabbitTemplate;
    
    // Configuration des appareils avec leurs priorités et consommations typiques
    private static final Map<String, DeviceInfo> DEVICE_CONFIG = createDeviceConfig();
    
    private static Map<String, DeviceInfo> createDeviceConfig() {
        Map<String, DeviceInfo> config = new HashMap<>();
        
        // Appareils basse priorité (peuvent être coupés facilement)
        config.put("washing-machine-1", new DeviceInfo("WASHING_MACHINE", "LOW", 0.8));
        config.put("dryer-1", new DeviceInfo("DRYER", "LOW", 1.0));
        config.put("microwave-1", new DeviceInfo("MICROWAVE", "LOW", 1.2));
        config.put("lamp-living-1", new DeviceInfo("LIGHT", "LOW", 0.06));
        config.put("lamp-living-2", new DeviceInfo("LIGHT", "LOW", 0.06));
        config.put("lamp-living-3", new DeviceInfo("LIGHT", "LOW", 0.06));
        config.put("lamp-room-1", new DeviceInfo("LIGHT", "LOW", 0.05));
        config.put("lamp-room-2", new DeviceInfo("LIGHT", "LOW", 0.05));
        config.put("lamp-room-3", new DeviceInfo("LIGHT", "LOW", 0.05));
        config.put("lamp-room-4", new DeviceInfo("LIGHT", "LOW", 0.05));
        
        // Appareils moyenne priorité (peuvent être mis en veille)
        config.put("tv-1", new DeviceInfo("TV", "MEDIUM", 0.1));
        config.put("aircon-1", new DeviceInfo("AIR_CONDITIONER", "MEDIUM", 1.5));
        config.put("heater-1", new DeviceInfo("HEATER", "MEDIUM", 1.8));
        config.put("oven-1", new DeviceInfo("OVEN", "MEDIUM", 2.0));
        
        // Appareils haute priorité (ne jamais couper)
        config.put("fridge-1", new DeviceInfo("FRIDGE", "HIGH", 0.15));
        
        return Collections.unmodifiableMap(config);
    }

    private record DeviceInfo(String type, String priority, double basePowerKw) {}

    @RabbitListener(queues = RabbitConfig.PEAK_ALERTS_QUEUE)
    public void handlePeakAlert(PeakEvent peakEvent) {
        log.info("⚡ Alerte de pic reçue: level={}, totalPower={}kW, id={}", 
                peakEvent.getLevel(), peakEvent.getTotalPowerKw(), peakEvent.getId());

        List<DeviceCommand> commands = decideActions(peakEvent);
        
        for (DeviceCommand command : commands) {
            sendCommand(command);
        }

        log.info("✅ {} commande(s) envoyée(s) pour réduire la consommation", commands.size());
    }

    private List<DeviceCommand> decideActions(PeakEvent peakEvent) {
        List<DeviceCommand> commands = new ArrayList<>();
        String level = peakEvent.getLevel();
        double totalPower = peakEvent.getTotalPowerKw();
        double targetReduction = calculateTargetReduction(level, totalPower);

        log.info("🎯 Décision: level={}, puissance={}kW, réduction cible={}kW", 
                level, totalPower, targetReduction);

        double currentReduction = 0.0;

        switch (level) {
            case "WARNING" -> {
                // Niveau WARNING: actions douces (retarder démarrage, éteindre lumières)
                currentReduction = handleWarningLevel(commands, targetReduction, currentReduction);
            }
            case "CRITICAL" -> {
                // Niveau CRITICAL: actions fortes (couper appareils, mettre en veille)
                currentReduction = handleCriticalLevel(commands, targetReduction, currentReduction);
            }
            default -> {
                log.warn("⚠️ Niveau d'alerte inconnu: {}", level);
            }
        }

        return commands;
    }

    private double calculateTargetReduction(String level, double currentPower) {
        // Objectif: réduire de 20% pour WARNING, 40% pour CRITICAL
        double reductionPercent = level.equals("CRITICAL") ? 0.40 : 0.20;
        return currentPower * reductionPercent;
    }

    private double handleWarningLevel(List<DeviceCommand> commands, double targetReduction, double currentReduction) {
        // 1. Éteindre les lumières (basse priorité, faible impact)
        for (String deviceId : DEVICE_CONFIG.keySet()) {
            if (currentReduction >= targetReduction) break;
            
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null && "LIGHT".equals(info.type()) && "LOW".equals(info.priority())) {
                commands.add(createCommand(deviceId, "TURN_OFF", 
                    "Réduction consommation - niveau WARNING"));
                currentReduction += info.basePowerKw();
            }
        }

        // 2. Retarder le démarrage des appareils basse priorité
        for (String deviceId : DEVICE_CONFIG.keySet()) {
            if (currentReduction >= targetReduction) break;
            
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null && "LOW".equals(info.priority()) && 
                (info.type().equals("WASHING_MACHINE") || info.type().equals("DRYER"))) {
                commands.add(createCommand(deviceId, "DELAY_START", 
                    "Réduction consommation - niveau WARNING", 30));
                currentReduction += info.basePowerKw() * 0.5; // Estimation
            }
        }

        return currentReduction;
    }

    private double handleCriticalLevel(List<DeviceCommand> commands, double targetReduction, double currentReduction) {
        // 1. Couper les appareils basse priorité
        for (String deviceId : DEVICE_CONFIG.keySet()) {
            if (currentReduction >= targetReduction) break;
            
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null && "LOW".equals(info.priority())) {
                commands.add(createCommand(deviceId, "TURN_OFF", 
                    "Réduction consommation - niveau CRITICAL"));
                currentReduction += info.basePowerKw();
            }
        }

        // 2. Mettre en veille les appareils moyenne priorité
        for (String deviceId : DEVICE_CONFIG.keySet()) {
            if (currentReduction >= targetReduction) break;
            
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null && "MEDIUM".equals(info.priority())) {
                // Pour les appareils énergivores, on peut les couper complètement
                if (info.basePowerKw() > 1.0) {
                    commands.add(createCommand(deviceId, "TURN_OFF", 
                        "Réduction consommation - niveau CRITICAL"));
                    currentReduction += info.basePowerKw();
                } else {
                    commands.add(createCommand(deviceId, "STANDBY", 
                        "Réduction consommation - niveau CRITICAL"));
                    currentReduction += info.basePowerKw() * 0.8; // 80% de réduction en veille
                }
            }
        }

        // 3. Réduire la puissance des appareils de climatisation/chauffage
        for (String deviceId : Arrays.asList("aircon-1", "heater-1")) {
            if (currentReduction >= targetReduction) break;
            
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null) {
                commands.add(createCommand(deviceId, "REDUCE_POWER", 
                    "Réduction consommation - niveau CRITICAL", 50.0));
                currentReduction += info.basePowerKw() * 0.5; // 50% de réduction
            }
        }

        return currentReduction;
    }

    private DeviceCommand createCommand(String deviceId, String action, String reason) {
        return createCommand(deviceId, action, reason, null, null);
    }

    private DeviceCommand createCommand(String deviceId, String action, String reason, Integer delayMinutes) {
        return createCommand(deviceId, action, reason, delayMinutes, null);
    }

    private DeviceCommand createCommand(String deviceId, String action, String reason, Double powerReductionPercent) {
        return createCommand(deviceId, action, reason, null, powerReductionPercent);
    }

    private DeviceCommand createCommand(String deviceId, String action, String reason, 
                                       Integer delayMinutes, Double powerReductionPercent) {
        DeviceCommand command = new DeviceCommand();
        command.setCommandId(UUID.randomUUID().toString());
        command.setDeviceId(deviceId);
        command.setAction(action);
        command.setDelayMinutes(delayMinutes);
        command.setPowerReductionPercent(powerReductionPercent);
        command.setReason(reason);
        command.setTimestamp(Instant.now());
        return command;
    }

    private void sendCommand(DeviceCommand command) {
        String routingKey = "device.command." + command.getDeviceId();
        
        rabbitTemplate.convertAndSend(
            RabbitConfig.CONTROL_COMMANDS_EXCHANGE,
            routingKey,
            command
        );

        log.info("📤 Commande envoyée: deviceId={}, action={}, reason={}", 
                command.getDeviceId(), command.getAction(), command.getReason());
    }
}
