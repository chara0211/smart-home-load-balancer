package com.smarthome.billing.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * Event published by usage-collector-service via RabbitMQ
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsageEvent {
    private LocalDateTime timestamp;
    private BigDecimal totalPowerKw;
    private Map<String, BigDecimal> devices; // deviceId -> powerKw
    private Boolean optimizationActive;
}
