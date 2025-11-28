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

    @PostConstruct
    void initDevices() {
        devices.add(new Device("fridge-1", DeviceType.FRIDGE, DevicePriority.HIGH,
                DeviceState.ON, 0.15, 0.15));
        devices.add(new Device("washing-machine-1", DeviceType.WASHING_MACHINE, DevicePriority.LOW,
                DeviceState.OFF, 0.8, 0.0));
        devices.add(new Device("tv-1", DeviceType.TV, DevicePriority.MEDIUM,
                DeviceState.STANDBY, 0.1, 0.02));
        devices.add(new Device("aircon-1", DeviceType.AIR_CONDITIONER, DevicePriority.MEDIUM,
                DeviceState.OFF, 1.5, 0.0));
        // tu peux ajouter d'autres appareils ici
    }

    @Scheduled(fixedRate = 5000) // toutes les 5 secondes
    public void simulateAndPublish() {
        for (Device device : devices) {
            updatePower(device);

            DeviceUsageEvent event = new DeviceUsageEvent(
                    device.getId(),
                    device.getType().name(),
                    device.getPriority().name(),
                    device.getState().name(),
                    device.getCurrentPowerKw(),
                    Instant.now()
            );

            rabbitTemplate.convertAndSend(
                    RabbitConfig.DEVICE_EVENTS_EXCHANGE,
                    "device.usage." + device.getType().name().toLowerCase(),
                    event
            );
        }
    }

    private void updatePower(Device device) {
        switch (device.getState()) {
            case OFF -> device.setCurrentPowerKw(0.0);
            case STANDBY -> device.setCurrentPowerKw(0.02);
            case ON -> {
                double noise = (random.nextDouble() - 0.5) * 0.1 * device.getBasePowerKw();
                device.setCurrentPowerKw(Math.max(0,
                        device.getBasePowerKw() + noise));
            }
        }
    }
}
