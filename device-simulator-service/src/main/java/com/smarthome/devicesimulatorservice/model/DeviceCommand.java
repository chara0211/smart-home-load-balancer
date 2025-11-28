package com.smarthome.devicesimulatorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DeviceCommand {

    private String commandId;
    private String deviceId;
    private String action;       // TURN_ON, TURN_OFF, STANDBY, DELAY_START
    private Integer delayMinutes;
    private String reason;
    private Instant timestamp;
}
