package com.smarthome.peakdetectorservice.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.Instant;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PeakEvent implements Serializable {

    private String id;
    private String level;          // "WARNING" ou "CRITICAL"
    private double totalPowerKw;
    private Instant timestamp;
}
