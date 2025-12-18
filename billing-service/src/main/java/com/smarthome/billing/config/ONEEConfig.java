package com.smarthome.billing.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;

/**
 * Configuration for Morocco ONEE (Office National de l'Electricité et de l'Eau potable) electricity rates
 * Based on residential tariff structure with tiered pricing
 */
@Configuration
@Getter
public class ONEEConfig {

    // Tiered rates (MAD/kWh) - Already including 14% TVA
    @Value("${billing.tier1.rate:1.06}")
    private BigDecimal tier1Rate; // 0-100 kWh: 0.93 + 14% TVA = 1.06

    @Value("${billing.tier2.rate:1.22}")
    private BigDecimal tier2Rate; // 101-200 kWh: 1.07 + 14% TVA = 1.22

    @Value("${billing.tier3.rate:1.35}")
    private BigDecimal tier3Rate; // 201-500 kWh: 1.18 + 14% TVA = 1.35

    @Value("${billing.tier4.rate:1.61}")
    private BigDecimal tier4Rate; // 500+ kWh: 1.41 + 14% TVA = 1.61

    // Fixed charges
    @Value("${billing.subscription:10.00}")
    private BigDecimal monthlySubscription; // MAD per month

    @Value("${billing.tax.rate:0.14}")
    private BigDecimal taxRate; // 14% TVA

    // Tier thresholds (kWh)
    public static final int TIER1_MAX = 100;
    public static final int TIER2_MAX = 200;
    public static final int TIER3_MAX = 500;

    /**
     * Get the appropriate rate for a given consumption level
     * @param monthlyKwh Total monthly consumption in kWh
     * @return Weighted average rate for the consumption
     */
    public BigDecimal getAverageRateForConsumption(BigDecimal monthlyKwh) {
        if (monthlyKwh.compareTo(BigDecimal.valueOf(TIER1_MAX)) <= 0) {
            return tier1Rate;
        } else if (monthlyKwh.compareTo(BigDecimal.valueOf(TIER2_MAX)) <= 0) {
            return tier2Rate;
        } else if (monthlyKwh.compareTo(BigDecimal.valueOf(TIER3_MAX)) <= 0) {
            return tier3Rate;
        } else {
            return tier4Rate;
        }
    }
}
