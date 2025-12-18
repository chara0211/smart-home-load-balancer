package com.smarthome.billing.model;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Aggregated monthly bill with ONEE tiered pricing breakdown
 */
@Entity
@Table(name = "monthly_bills", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"month", "year"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MonthlyBill {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private Integer month; // 1-12

    @Column(nullable = false)
    private Integer year;

    @Column(name = "total_kwh", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalKwh;

    @Column(name = "total_cost_mad", nullable = false, precision = 10, scale = 2)
    private BigDecimal totalCostMad;

    // Tier breakdown
    @Column(name = "tier1_kwh", precision = 10, scale = 2)
    private BigDecimal tier1Kwh = BigDecimal.ZERO;

    @Column(name = "tier2_kwh", precision = 10, scale = 2)
    private BigDecimal tier2Kwh = BigDecimal.ZERO;

    @Column(name = "tier3_kwh", precision = 10, scale = 2)
    private BigDecimal tier3Kwh = BigDecimal.ZERO;

    @Column(name = "tier4_kwh", precision = 10, scale = 2)
    private BigDecimal tier4Kwh = BigDecimal.ZERO;

    // Cost components
    @Column(name = "energy_cost_mad", precision = 10, scale = 2)
    private BigDecimal energyCostMad;

    @Column(name = "taxes_mad", precision = 10, scale = 2)
    private BigDecimal taxesMad;

    @Column(name = "subscription_mad", precision = 10, scale = 2)
    private BigDecimal subscriptionMad = BigDecimal.valueOf(10.00);

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
