package com.smarthome.usagecollectorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeviceUsageEvent {
    private String deviceId;
    private double currentPowerKw;
}
