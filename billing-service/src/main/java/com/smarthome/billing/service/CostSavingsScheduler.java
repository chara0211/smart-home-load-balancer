package com.smarthome.billing.service;

import com.smarthome.billing.model.CostSavings;
import com.smarthome.billing.repository.CostSavingsRepository;
import com.smarthome.billing.repository.EnergyConsumptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class CostSavingsScheduler {

    private final CostSavingsRepository costSavingsRepository;
    private final EnergyConsumptionRepository consumptionRepository;

    // Every minute for testing (production: once/day)
    @Scheduled(cron = "0 * * * * *")
    public void upsertToday() {
        LocalDate today = LocalDate.now();
        LocalDateTime start = today.atStartOfDay();
        LocalDateTime end = start.plusDays(1);

        BigDecimal actualRaw = consumptionRepository.sumActualCostBetween(start, end);
        BigDecimal baselineRaw = consumptionRepository.sumBaselineCostBetween(start, end);

        if (actualRaw == null) actualRaw = BigDecimal.ZERO;
        if (baselineRaw == null) baselineRaw = BigDecimal.ZERO;

        final BigDecimal finalActual = actualRaw.setScale(2, RoundingMode.HALF_UP);

        final BigDecimal finalBaseline =
                (baselineRaw.compareTo(BigDecimal.ZERO) == 0 && finalActual.compareTo(BigDecimal.ZERO) > 0)
                        ? finalActual.multiply(BigDecimal.valueOf(1.15)).setScale(2, RoundingMode.HALF_UP)
                        : baselineRaw.setScale(2, RoundingMode.HALF_UP);

        final BigDecimal finalSavings =
                finalBaseline.subtract(finalActual).setScale(2, RoundingMode.HALF_UP);

        CostSavings cs = costSavingsRepository.findByDate(today)
                .map(existing -> {
                    existing.setActualCostMad(finalActual);
                    existing.setBaselineCostMad(finalBaseline);
                    existing.setSavingsMad(finalSavings);
                    return existing;
                })
                .orElseGet(() -> CostSavings.builder()
                        .date(today)
                        .actualCostMad(finalActual)
                        .baselineCostMad(finalBaseline)
                        .savingsMad(finalSavings)
                        .peaksPrevented(0)
                        .automationActions(0)
                        .build());

        costSavingsRepository.save(cs);

        log.info("✅ cost_savings upsert for {} baseline={} actual={} savings={}",
                today, finalBaseline, finalActual, finalSavings);
    }
}
