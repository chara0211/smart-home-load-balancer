package com.smarthome.billing.service;

import com.smarthome.billing.config.ONEEConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Service for calculating energy costs using Morocco ONEE tiered pricing
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CostCalculationService {

    private final ONEEConfig oneeConfig;

    /**
     * Calculate total monthly cost using ONEE tiered pricing structure
     * @param totalKwh Total monthly consumption in kWh
     * @return Total cost in MAD including all tiers, taxes, and subscription
     */
    public BigDecimal calculateMonthlyCost(BigDecimal totalKwh) {
        if (totalKwh == null || totalKwh.compareTo(BigDecimal.ZERO) <= 0) {
            return oneeConfig.getMonthlySubscription();
        }

        BigDecimal cost = BigDecimal.ZERO;
        BigDecimal remaining = totalKwh;

        // Tier 1: First 100 kWh at tier1 rate
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal tier1Kwh = remaining.min(BigDecimal.valueOf(ONEEConfig.TIER1_MAX));
            cost = cost.add(tier1Kwh.multiply(oneeConfig.getTier1Rate()));
            remaining = remaining.subtract(tier1Kwh);
            log.debug("Tier 1: {} kWh × {} MAD = {} MAD", tier1Kwh, oneeConfig.getTier1Rate(), tier1Kwh.multiply(oneeConfig.getTier1Rate()));
        }

        // Tier 2: Next 100 kWh (101-200) at tier2 rate
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal tier2Kwh = remaining.min(BigDecimal.valueOf(ONEEConfig.TIER2_MAX - ONEEConfig.TIER1_MAX));
            cost = cost.add(tier2Kwh.multiply(oneeConfig.getTier2Rate()));
            remaining = remaining.subtract(tier2Kwh);
            log.debug("Tier 2: {} kWh × {} MAD = {} MAD", tier2Kwh, oneeConfig.getTier2Rate(), tier2Kwh.multiply(oneeConfig.getTier2Rate()));
        }

        // Tier 3: Next 300 kWh (201-500) at tier3 rate
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal tier3Kwh = remaining.min(BigDecimal.valueOf(ONEEConfig.TIER3_MAX - ONEEConfig.TIER2_MAX));
            cost = cost.add(tier3Kwh.multiply(oneeConfig.getTier3Rate()));
            remaining = remaining.subtract(tier3Kwh);
            log.debug("Tier 3: {} kWh × {} MAD = {} MAD", tier3Kwh, oneeConfig.getTier3Rate(), tier3Kwh.multiply(oneeConfig.getTier3Rate()));
        }

        // Tier 4: Everything above 500 kWh at tier4 rate
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            cost = cost.add(remaining.multiply(oneeConfig.getTier4Rate()));
            log.debug("Tier 4: {} kWh × {} MAD = {} MAD", remaining, oneeConfig.getTier4Rate(), remaining.multiply(oneeConfig.getTier4Rate()));
        }

        // Add monthly subscription
        cost = cost.add(oneeConfig.getMonthlySubscription());

        log.info("Total monthly cost for {} kWh: {} MAD", totalKwh, cost);
        return cost.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculate hourly cost (simplified - uses average tier 2 rate)
     * @param powerKw Power consumption in kW
     * @return Hourly cost in MAD
     */
    public BigDecimal calculateHourlyCost(BigDecimal powerKw) {
        if (powerKw == null || powerKw.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        // Use tier 2 rate as average (most common tier for residential)
        BigDecimal cost = powerKw.multiply(oneeConfig.getTier2Rate());
        return cost.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculate cost for a specific duration
     * @param powerKw Power consumption in kW
     * @param hours Duration in hours
     * @return Total cost in MAD
     */
    public BigDecimal calculateCostForDuration(BigDecimal powerKw, BigDecimal hours) {
        if (powerKw == null || hours == null) {
            return BigDecimal.ZERO;
        }

        BigDecimal kWh = powerKw.multiply(hours);
        BigDecimal cost = kWh.multiply(oneeConfig.getTier2Rate());
        return cost.setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Project monthly cost based on current daily average
     * @param dailyKwh Average daily consumption
     * @param daysInMonth Number of days in the month
     * @return Projected monthly cost in MAD
     */
    public BigDecimal projectMonthlyCost(BigDecimal dailyKwh, int daysInMonth) {
        BigDecimal monthlyKwh = dailyKwh.multiply(BigDecimal.valueOf(daysInMonth));
        return calculateMonthlyCost(monthlyKwh);
    }
}
