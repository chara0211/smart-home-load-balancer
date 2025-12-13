package com.smarthome.billing.consumer;

import com.smarthome.billing.dto.DeviceUsageEvent;
import com.smarthome.billing.model.EnergyConsumption;
import com.smarthome.billing.repository.EnergyConsumptionRepository;
import com.smarthome.billing.service.CostCalculationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

/**
 * Consumes device usage events from RabbitMQ and stores them with calculated costs
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class UsageEventConsumer {

    private final EnergyConsumptionRepository consumptionRepository;
    private final CostCalculationService costCalculationService;

    @RabbitListener(queues = "usage.events")
    public void handleUsageEvent(DeviceUsageEvent event) {
        try {
            BigDecimal powerKw = event.getCurrentPowerKw() != null ? event.getCurrentPowerKw() : BigDecimal.ZERO;

            // Producer sends epoch seconds as a number (double). Convert to LocalDateTime (UTC).
            LocalDateTime ts = LocalDateTime.now();
            if (event.getTimestamp() != null) {
                long epochSeconds = event.getTimestamp().longValue();
                ts = LocalDateTime.ofInstant(Instant.ofEpochSecond(epochSeconds), ZoneOffset.UTC);
            }

            log.debug("Received device usage event: deviceId={}, powerKw={}, ts={}",
                    event.getDeviceId(), powerKw, ts);

            // Calculate hourly cost (your existing logic)
            BigDecimal cost = costCalculationService.calculateHourlyCost(powerKw);

            EnergyConsumption consumption = EnergyConsumption.builder()
                    .timestamp(ts)
                    .totalPowerKw(powerKw)
                    .totalCostMad(cost)
                    .withOptimization(true) // device simulator event doesn't contain this -> default true
                    .build();

            consumptionRepository.save(consumption);

            log.info("Saved energy consumption: deviceId={} {} kW = {} MAD",
                    event.getDeviceId(), powerKw, cost);

        } catch (Exception e) {
            log.error("Error processing device usage event", e);
        }
    }
}
