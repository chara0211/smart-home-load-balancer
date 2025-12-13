package com.smarthome.billing.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Tracks energy consumption snapshots with calculated costs
 */
@Entity
@Table(name = "energy_consumption", indexes = {
    @Index(name = "idx_consumption_timestamp", columnList = "timestamp")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EnergyConsumption {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(name = "total_power_kw", nullable = false, precision = 10, scale = 3)
    private BigDecimal totalPowerKw;

    @Column(name = "total_cost_mad", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalCostMad;

    @Column(name = "with_optimization", nullable = false)
    private Boolean withOptimization = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
