package com.smarthome.billing.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HistoricalPointDTO {
    private LocalDate date;
    private BigDecimal kwh;
    private BigDecimal costMad;
}
