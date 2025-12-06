package com.smarthome.devicesimulatorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.Instant;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DeviceUsageEvent implements Serializable {
    private String deviceId;
    private String deviceType;
    private String priority;
    private String state;
    private double currentPowerKw;
    private Instant timestamp;
}
