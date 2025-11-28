package com.smarthome.usagecollectorservice.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "home_usage")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HomeUsage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "total_power_kw", nullable = false)
    private double totalPowerKw;
    
    @Column(name = "timestamp", nullable = false)
    private Instant timestamp;
}
