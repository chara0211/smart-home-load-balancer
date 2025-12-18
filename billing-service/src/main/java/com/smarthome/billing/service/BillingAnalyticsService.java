package com.smarthome.billing.service;

import com.smarthome.billing.dto.*;
import com.smarthome.billing.model.CostSavings;
import com.smarthome.billing.model.MonthlyBill;
import com.smarthome.billing.repository.CostSavingsRepository;
import com.smarthome.billing.repository.EnergyConsumptionRepository;
import com.smarthome.billing.repository.MonthlyBillRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class BillingAnalyticsService {

    private final MonthlyBillRepository monthlyBillRepository;
    private final CostSavingsRepository costSavingsRepository;
    private final EnergyConsumptionRepository consumptionRepository;
    private final CostCalculationService costCalculationService;

    public MonthlyBillDTO getCurrentMonthBill() {
        LocalDate now = LocalDate.now();
        int currentMonth = now.getMonthValue();
        int currentYear = now.getYear();

        MonthlyBill bill = monthlyBillRepository
                .findByMonthAndYear(currentMonth, currentYear)
                .orElse(buildCurrentMonthBill(currentMonth, currentYear));

        return mapToDTO(bill);
    }

    public SavingsDTO getTotalSavings() {
        LocalDate firstOfMonth = LocalDate.now().withDayOfMonth(1);
        
        BigDecimal monthlySavings = costSavingsRepository.sumSavingsSince(firstOfMonth);
        Integer peaksPrevented = costSavingsRepository.sumPeaksPreventedSince(firstOfMonth);
        Integer automationActions = costSavingsRepository.sumAutomationActionsSince(firstOfMonth);

        LocalDate firstOfYear = LocalDate.now().withDayOfYear(1);
        BigDecimal totalSavings = costSavingsRepository.sumSavingsSince(firstOfYear);

        // Get today's savings
        BigDecimal dailySavings = costSavingsRepository.findByDate(LocalDate.now())
                .map(CostSavings::getSavingsMad)
                .orElse(BigDecimal.ZERO);

        return SavingsDTO.builder()
                .totalSavingsMad(totalSavings != null ? totalSavings : BigDecimal.ZERO)
                .monthlySavingsMad(monthlySavings != null ? monthlySavings : BigDecimal.ZERO)
                .dailySavingsMad(dailySavings)
                .totalPeaksPrevented(peaksPrevented != null ? peaksPrevented : 0)
                .totalAutomationActions(automationActions != null ? automationActions : 0)
                .build();
    }

    public DailyCostDTO getTodayCost() {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);

        BigDecimal todayCost = consumptionRepository.sumCostBetween(startOfDay, endOfDay);
        BigDecimal todayPower = consumptionRepository.sumPowerBetween(startOfDay, endOfDay);

        // Convert total power to kWh (assuming readings every minute)
        BigDecimal todayKwh = todayPower != null 
            ? todayPower.divide(BigDecimal.valueOf(60), 3, RoundingMode.HALF_UP) 
            : BigDecimal.ZERO;

        // Project full day cost
        int currentHour = LocalDateTime.now().getHour();
        BigDecimal projectedDailyCost = BigDecimal.ZERO;
        if (currentHour > 0 && todayCost != null) {
            BigDecimal avgHourlyCost = todayCost.divide(BigDecimal.valueOf(currentHour), 2, RoundingMode.HALF_UP);
            projectedDailyCost = avgHourlyCost.multiply(BigDecimal.valueOf(24));
        }

        return DailyCostDTO.builder()
                .todayCostMad(todayCost != null ? todayCost : BigDecimal.ZERO)
                .todayKwh(todayKwh)
                .projectedDailyCostMad(projectedDailyCost)
                .build();
    }

    public List<HistoricalCostDTO> getHistory(String range) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = switch (range) {
            case "7d" -> endDate.minusDays(7);
            case "30d" -> endDate.minusDays(30);
            case "90d" -> endDate.minusDays(90);
            default -> endDate.minusDays(30);
        };

        List<CostSavings> savings = costSavingsRepository.findByDateBetweenOrderByDateDesc(startDate, endDate);
        List<HistoricalCostDTO> history = new ArrayList<>();

        for (CostSavings saving : savings) {
            LocalDateTime dayStart = saving.getDate().atStartOfDay();
            LocalDateTime dayEnd = dayStart.plusDays(1);

            BigDecimal dayCost = consumptionRepository.sumCostBetween(dayStart, dayEnd);
            BigDecimal dayPower = consumptionRepository.sumPowerBetween(dayStart, dayEnd);
            BigDecimal dayKwh = dayPower != null 
                ? dayPower.divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP) 
                : BigDecimal.ZERO;

            history.add(HistoricalCostDTO.builder()
                    .date(saving.getDate().toString())
                    .costMad(dayCost != null ? dayCost : BigDecimal.ZERO)
                    .kwh(dayKwh)
                    .savingsMad(saving.getSavingsMad())
                    .build());
        }

        return history;
    }

    private MonthlyBill buildCurrentMonthBill(int month, int year) {
        LocalDate firstDay = LocalDate.of(year, month, 1);
        LocalDate lastDay = YearMonth.of(year, month).atEndOfMonth();
        
        LocalDateTime start = firstDay.atStartOfDay();
        LocalDateTime end = lastDay.atTime(23, 59, 59);

        BigDecimal totalCost = consumptionRepository.sumCostBetween(start, end);
        BigDecimal totalPower = consumptionRepository.sumPowerBetween(start, end);
        
        // Convert to kWh (rough estimate)
        BigDecimal totalKwh = totalPower != null 
            ? totalPower.divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP) 
            : BigDecimal.ZERO;

        return MonthlyBill.builder()
                .month(month)
                .year(year)
                .totalKwh(totalKwh)
                .totalCostMad(totalCost != null ? totalCost : BigDecimal.ZERO)
                .energyCostMad(totalCost != null ? totalCost : BigDecimal.ZERO)
                .subscriptionMad(BigDecimal.valueOf(10.00))
                .build();
    }

    private MonthlyBillDTO mapToDTO(MonthlyBill bill) {
        // Project full month based on current progress
        int currentDay = LocalDate.now().getDayOfMonth();
        int daysInMonth = YearMonth.of(bill.getYear(), bill.getMonth()).lengthOfMonth();
        
        BigDecimal projectedKwh = BigDecimal.ZERO;
        BigDecimal projectedCost = BigDecimal.ZERO;
        
        if (currentDay > 0 && bill.getTotalKwh().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal dailyAvg = bill.getTotalKwh().divide(BigDecimal.valueOf(currentDay), 2, RoundingMode.HALF_UP);
            projectedKwh = dailyAvg.multiply(BigDecimal.valueOf(daysInMonth));
            projectedCost = costCalculationService.calculateMonthlyCost(projectedKwh);
        }

        return MonthlyBillDTO.builder()
                .month(bill.getMonth())
                .year(bill.getYear())
                .totalKwh(bill.getTotalKwh())
                .totalCostMad(bill.getTotalCostMad())
                .energyCostMad(bill.getEnergyCostMad())
                .taxesMad(bill.getTaxesMad())
                .subscriptionMad(bill.getSubscriptionMad())
                .tier1Kwh(bill.getTier1Kwh())
                .tier2Kwh(bill.getTier2Kwh())
                .tier3Kwh(bill.getTier3Kwh())
                .tier4Kwh(bill.getTier4Kwh())
                .projectedMonthlyKwh(projectedKwh)
                .projectedMonthlyCostMad(projectedCost)
                .build();
    }
}
