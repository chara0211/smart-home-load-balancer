package com.smarthome.billing.controller;

import com.smarthome.billing.dto.*;
import com.smarthome.billing.service.BillingAnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST API for billing and cost analytics
 */
@RestController
@RequestMapping("/billing")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class BillingController {

    private final BillingAnalyticsService analyticsService;

    /**
     * Get current month billing information with projections
     */
    @GetMapping("/current-month")
    public ResponseEntity<MonthlyBillDTO> getCurrentMonth() {
        log.info("GET /billing/current-month");
        MonthlyBillDTO bill = analyticsService.getCurrentMonthBill();
        return ResponseEntity.ok(bill);
    }

    /**
     * Get total savings achieved through optimization
     */
    @GetMapping("/savings")
    public ResponseEntity<SavingsDTO> getSavings() {
        log.info("GET /billing/savings");
        SavingsDTO savings = analyticsService.getTotalSavings();
        return ResponseEntity.ok(savings);
    }

    /**
     * Get today's cost and consumption
     */
    @GetMapping("/daily-cost")
    public ResponseEntity<DailyCostDTO> getDailyCost() {
        log.info("GET /billing/daily-cost");
        DailyCostDTO cost = analyticsService.getTodayCost();
        return ResponseEntity.ok(cost);
    }

    /**
     * Get historical cost data
     * @param range Time range: 7d, 30d, 90d (default: 30d)
     */
    @GetMapping("/history")
    public ResponseEntity<List<HistoricalCostDTO>> getHistory(
            @RequestParam(defaultValue = "30d") String range
    ) {
        log.info("GET /billing/history?range={}", range);
        List<HistoricalCostDTO> history = analyticsService.getHistory(range);
        return ResponseEntity.ok(history);
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Billing service is running");
    }
}
