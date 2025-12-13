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
import java.util.concurrent.ConcurrentLinkedDeque;

@Slf4j
@Service
@RequiredArgsConstructor
public class OptimizerService {

    private final RabbitTemplate rabbitTemplate;

    // =========================
    // 🔥 LOG BUFFER (OPTION 1)
    // =========================
    private final Deque<String> recentLogs = new ConcurrentLinkedDeque<>();
    private static final int MAX_LOGS = 200;

    private void pushLog(String msg) {
        String line = Instant.now() + " " + msg;
        recentLogs.addFirst(line);
        while (recentLogs.size() > MAX_LOGS) {
            recentLogs.removeLast();
        }
    }

    public List<String> getRecentLogs(int limit) {
        return recentLogs.stream().limit(limit).toList();
    }

    // =========================
    // DEVICE CONFIG
    // =========================
    private static final Map<String, DeviceInfo> DEVICE_CONFIG = createDeviceConfig();

    private static Map<String, DeviceInfo> createDeviceConfig() {
        Map<String, DeviceInfo> config = new HashMap<>();

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

        config.put("tv-1", new DeviceInfo("TV", "MEDIUM", 0.1));
        config.put("aircon-1", new DeviceInfo("AIR_CONDITIONER", "MEDIUM", 1.5));
        config.put("heater-1", new DeviceInfo("HEATER", "MEDIUM", 1.8));
        config.put("oven-1", new DeviceInfo("OVEN", "MEDIUM", 2.0));

        config.put("fridge-1", new DeviceInfo("FRIDGE", "HIGH", 0.15));

        return Collections.unmodifiableMap(config);
    }

    private record DeviceInfo(String type, String priority, double basePowerKw) {}

    // =========================
    // RABBIT LISTENER
    // =========================
    @RabbitListener(queues = RabbitConfig.PEAK_ALERTS_QUEUE)
    public void handlePeakAlert(PeakEvent peakEvent) {
        log.info("⚡ Alerte de pic reçue: level={}, totalPower={}kW, id={}",
                peakEvent.getLevel(), peakEvent.getTotalPowerKw(), peakEvent.getId());

        pushLog("⚡ Peak alert received | level=" + peakEvent.getLevel()
                + " | power=" + peakEvent.getTotalPowerKw() + "kW");

        List<DeviceCommand> commands = decideActions(peakEvent);

        for (DeviceCommand command : commands) {
            sendCommand(command);
        }

        log.info("✅ {} commande(s) envoyée(s)", commands.size());
        pushLog("✅ " + commands.size() + " command(s) sent");
    }

    private List<DeviceCommand> decideActions(PeakEvent peakEvent) {
        List<DeviceCommand> commands = new ArrayList<>();

        String level = peakEvent.getLevel();
        double totalPower = peakEvent.getTotalPowerKw();
        double targetReduction = calculateTargetReduction(level, totalPower);

        log.info("🎯 Décision: level={}, réduction cible={}kW", level, targetReduction);
        pushLog("🎯 Decision | level=" + level + " | targetReduction=" + targetReduction + "kW");

        double currentReduction = 0.0;

        if ("WARNING".equals(level)) {
            currentReduction = handleWarningLevel(commands, targetReduction, currentReduction);
        } else if ("CRITICAL".equals(level)) {
            currentReduction = handleCriticalLevel(commands, targetReduction, currentReduction);
        }

        return commands;
    }

    private double calculateTargetReduction(String level, double currentPower) {
        return level.equals("CRITICAL") ? currentPower * 0.40 : currentPower * 0.20;
    }

    // =========================
    // ACTION HANDLERS (inchangés)
    // =========================
    private double handleWarningLevel(List<DeviceCommand> commands, double targetReduction, double currentReduction) {
        for (String deviceId : DEVICE_CONFIG.keySet()) {
            if (currentReduction >= targetReduction) break;
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null && "LOW".equals(info.priority())) {
                commands.add(createCommand(deviceId, "TURN_OFF", "WARNING reduction"));
                currentReduction += info.basePowerKw();
            }
        }
        return currentReduction;
    }

    private double handleCriticalLevel(List<DeviceCommand> commands, double targetReduction, double currentReduction) {
        for (String deviceId : DEVICE_CONFIG.keySet()) {
            if (currentReduction >= targetReduction) break;
            DeviceInfo info = DEVICE_CONFIG.get(deviceId);
            if (info != null && "LOW".equals(info.priority())) {
                commands.add(createCommand(deviceId, "TURN_OFF", "CRITICAL reduction"));
                currentReduction += info.basePowerKw();
            }
        }
        return currentReduction;
    }

    private DeviceCommand createCommand(String deviceId, String action, String reason) {
        DeviceCommand command = new DeviceCommand();
        command.setCommandId(UUID.randomUUID().toString());
        command.setDeviceId(deviceId);
        command.setAction(action);
        command.setReason(reason);
        command.setTimestamp(Instant.now());
        return command;
    }

    private void sendCommand(DeviceCommand command) {
        rabbitTemplate.convertAndSend(
                RabbitConfig.CONTROL_COMMANDS_EXCHANGE,
                "device.command." + command.getDeviceId(),
                command
        );

        log.info("📤 Commande envoyée: {} {}", command.getDeviceId(), command.getAction());
        pushLog("📤 Command sent | " + command.getDeviceId() + " → " + command.getAction());
    }
}
