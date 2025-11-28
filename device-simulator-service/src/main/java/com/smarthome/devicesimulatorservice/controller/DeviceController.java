package com.smarthome.devicesimulatorservice.controller;

import com.smarthome.devicesimulatorservice.model.Device;
import com.smarthome.devicesimulatorservice.service.DeviceSimulationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class DeviceController {

    private final DeviceSimulationService deviceSimulationService;

    public DeviceController(DeviceSimulationService deviceSimulationService) {
        this.deviceSimulationService = deviceSimulationService;
    }

    // Voir tous les appareils simulés
    @GetMapping("/devices")
    public List<Device> getDevices() {
        return deviceSimulationService.getDevices();
    }
}
