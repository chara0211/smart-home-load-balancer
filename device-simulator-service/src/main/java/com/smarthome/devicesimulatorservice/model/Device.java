package com.smarthome.devicesimulatorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor       // constructeur avec tous les champs
@NoArgsConstructor        // constructeur vide
public class Device {

    private String id;
    private DeviceType type;
    private DevicePriority priority;
    private DeviceState state;
    private double basePowerKw;
    private double currentPowerKw;
}
