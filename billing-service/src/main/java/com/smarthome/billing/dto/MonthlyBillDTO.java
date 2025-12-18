package com.smarthome.billing.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MonthlyBillDTO {
    private Integer month;
    private Integer year;
    private BigDecimal totalKwh;
    private BigDecimal totalCostMad;
    private BigDecimal energyCostMad;
    private BigDecimal taxesMad;
    private BigDecimal subscriptionMad;

    private BigDecimal tier1Kwh;
    private BigDecimal tier2Kwh;
    private BigDecimal tier3Kwh;
    private BigDecimal tier4Kwh;

    private BigDecimal projectedMonthlyKwh;
    private BigDecimal projectedMonthlyCostMad;
}
