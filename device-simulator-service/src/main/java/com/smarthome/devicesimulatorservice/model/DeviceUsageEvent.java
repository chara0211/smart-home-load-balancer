package com.smarthome.devicesimulatorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@AllArgsConstructor     // constructeur avec 6 arguments
@NoArgsConstructor      // constructeur vide
public class DeviceUsageEvent {

    private String deviceId;
    private String type;
    private String priority;
    private String state;
    private double currentPowerKw;
    private Instant timestamp;
}
