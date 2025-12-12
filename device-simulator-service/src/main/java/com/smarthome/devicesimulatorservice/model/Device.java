package com.smarthome.devicesimulatorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Device implements Serializable {
    private String id;
    private DeviceType type;
    private DevicePriority priority;
    private DeviceState state;
    private double basePowerKw;
    private double currentPowerKw;
}