package com.smarthome.billing.dto;

import lombok.*;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HistoricalCostDTO {
    private String date;          // ✅ required by .date(...)
    private BigDecimal kwh;       // ✅ required by .kwh(...)
    private BigDecimal costMad;   // ✅ required by .costMad(...)
    private BigDecimal savingsMad;// ✅ required by .savingsMad(...)
}
