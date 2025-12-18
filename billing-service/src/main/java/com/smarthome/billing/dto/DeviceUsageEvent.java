package com.smarthome.billing.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class DeviceUsageEvent {

    private String deviceId;
    private String deviceType;
    private String priority;
    private String state;
    private BigDecimal currentPowerKw;

    // producer sends epoch seconds → double
    private Double timestamp;
}
