package com.smarthome.billing.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyCostDTO {
    private BigDecimal todayCostMad;
    private BigDecimal todayKwh;
    private BigDecimal projectedDailyCostMad;
}
