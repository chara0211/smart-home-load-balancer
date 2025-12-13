package com.smarthome.billing.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SavingsDTO {
    private BigDecimal totalSavingsMad;
    private BigDecimal monthlySavingsMad;
    private BigDecimal dailySavingsMad;
    private Integer totalPeaksPrevented;
    private Integer totalAutomationActions;
}
