package com.smarthome.peakdetectorservice.model;


import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PeakEvent {

    private String id;           // UUID de l’événement
    private String level;        // WARNING / CRITICAL
    private double totalPowerKw; // puissance totale
    private Instant timestamp;
}
