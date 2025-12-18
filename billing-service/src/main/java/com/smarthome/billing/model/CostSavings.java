package com.smarthome.billing.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Tracks daily cost savings achieved through optimization
 * Compares baseline cost (without optimizer) vs actual cost (with optimizer)
 */
@Entity
@Table(name = "cost_savings", indexes = {
    @Index(name = "idx_savings_date", columnList = "date")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CostSavings {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true)
    private LocalDate date;

    @Column(name = "baseline_cost_mad", nullable = false, precision = 10, scale = 2)
    private BigDecimal baselineCostMad; // What it would cost WITHOUT optimization

    @Column(name = "actual_cost_mad", nullable = false, precision = 10, scale = 2)
    private BigDecimal actualCostMad; // What it actually cost WITH optimization

    @Column(name = "savings_mad", nullable = false, precision = 10, scale = 2)
    private BigDecimal savingsMad; // Difference = baseline - actual

    @Column(name = "peaks_prevented")
    private Integer peaksPrevented = 0;

    @Column(name = "automation_actions")
    private Integer automationActions = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        // Auto-calculate savings
        if (savingsMad == null && baselineCostMad != null && actualCostMad != null) {
            savingsMad = baselineCostMad.subtract(actualCostMad);
        }
    }
}
