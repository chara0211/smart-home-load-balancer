package com.smarthome.devicesimulatorservice.service;

import com.smarthome.devicesimulatorservice.config.RabbitConfig;
import com.smarthome.devicesimulatorservice.model.*;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Service
public class DeviceSimulationService {

    private final RabbitTemplate rabbitTemplate;
    private final Random random = new Random();

    private final List<Device> devices = new ArrayList<>();

    public DeviceSimulationService(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public List<Device> getDevices() {
        return devices;
    }

    // ============================================================
    // 1) INITIALISATION DES DEVICES
    // ============================================================
    @PostConstruct
    void initDevices() {

        // === Cuisine ===
        devices.add(createDevice("fridge-1", DeviceType.FRIDGE, DevicePriority.HIGH, 0.15));
        devices.add(createDevice("oven-1", DeviceType.OVEN, DevicePriority.MEDIUM, 2.0));
        devices.add(createDevice("microwave-1", DeviceType.MICROWAVE, DevicePriority.LOW, 1.2));

        // === Salon ===
        devices.add(createDevice("tv-1", DeviceType.TV, DevicePriority.MEDIUM, 0.1));
        for (int i = 1; i <= 3; i++) {
            devices.add(createDevice("lamp-living-" + i, DeviceType.LIGHT, DevicePriority.LOW, 0.06));
        }

        // === Climatisation / chauffage ===
        devices.add(createDevice("aircon-1", DeviceType.AIR_CONDITIONER, DevicePriority.MEDIUM, 1.5));
        devices.add(createDevice("heater-1", DeviceType.HEATER, DevicePriority.MEDIUM, 1.8));

        // === Buanderie ===
        devices.add(createDevice("washing-machine-1", DeviceType.WASHING_MACHINE, DevicePriority.LOW, 0.8));
        devices.add(createDevice("dryer-1", DeviceType.DRYER, DevicePriority.LOW, 1.0));

        // === Lumières chambres ===
        for (int i = 1; i <= 4; i++) {
            devices.add(createDevice("lamp-room-" + i, DeviceType.LIGHT, DevicePriority.LOW, 0.05));
        }

        System.out.println("📌 " + devices.size() + " devices initialized.");
    }

    private Device createDevice(String id, DeviceType type, DevicePriority priority, double basePowerKw) {
        DeviceState initialState = (priority == DevicePriority.HIGH) ? DeviceState.ON : DeviceState.OFF;
        double initialPower = initialState == DeviceState.ON ? basePowerKw : 0.0;

        return new Device(id, type, priority, initialState, basePowerKw, initialPower);
    }

    // ============================================================
    // 2) SIMULATION : exécuté toutes les 5 secondes
    // ============================================================
    @Scheduled(fixedRate = 5000)
    public void simulateAndPublish() {

        System.out.println("\n🔁 === New Simulation Tick (" + devices.size() + " devices) ===");

        for (Device device : devices) {

            // 1) Peut changer d'état aléatoirement
            maybeChangeState(device);

            // 2) Mise à jour de la consommation
            updatePower(device);

            // 🔎 LOG COMPLET DU DEVICE
            System.out.println(
                    " Device: " + device.getId() + "\n" +
                            "   • Type     : " + device.getType() + "\n" +
                            "   • Priority : " + device.getPriority() + "\n" +
                            "   • State    : " + device.getState() + "\n" +
                            "   • Power    : " + device.getCurrentPowerKw() + " kW"
            );

            // 3) Création de l'événement
            DeviceUsageEvent event = new DeviceUsageEvent(
                    device.getId(),
                    device.getType().name(),
                    device.getPriority().name(),
                    device.getState().name(),
                    device.getCurrentPowerKw(),
                    Instant.now()
            );

            // 4) Envoi à RabbitMQ
            rabbitTemplate.convertAndSend(
                    RabbitConfig.DEVICE_EVENTS_EXCHANGE,
                    "device.usage." + device.getType().name().toLowerCase(),
                    event
            );

            System.out.println("📤 Sent DeviceUsageEvent → " + event);
        }
    }

    // ============================================================
    // 3) Simulation du changement d'état aléatoire
    // ============================================================
    private void maybeChangeState(Device device) {

        double p = random.nextDouble();

        switch (device.getState()) {
            case OFF -> {
                if (p < 0.10) device.setState(DeviceState.ON);
                else if (p < 0.15) device.setState(DeviceState.STANDBY);
            }
            case ON -> {
                if (p < 0.05) device.setState(DeviceState.OFF);
                else if (p < 0.15) device.setState(DeviceState.STANDBY);
            }
            case STANDBY -> {
                if (p < 0.20) device.setState(DeviceState.ON);
                else if (p < 0.25) device.setState(DeviceState.OFF);
            }
        }
    }

    // ============================================================
    // 4) Simulation consommation électrique
    // ============================================================
    private void updatePower(Device device) {

        switch (device.getState()) {
            case OFF -> device.setCurrentPowerKw(0.0);
            case STANDBY -> device.setCurrentPowerKw(0.02);
            case ON -> {
                double noise = (random.nextDouble() - 0.5) * 0.1 * device.getBasePowerKw();
                device.setCurrentPowerKw(Math.max(0, device.getBasePowerKw() + noise));
            }
        }
    }
}
