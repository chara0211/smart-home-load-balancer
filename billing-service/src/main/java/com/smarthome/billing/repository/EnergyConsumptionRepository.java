package com.smarthome.billing.repository;

import com.smarthome.billing.model.EnergyConsumption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Repository
public interface EnergyConsumptionRepository extends JpaRepository<EnergyConsumption, UUID> {

    //  Used by BillingAnalyticsService (fixes compilation)
    @Query("""
        SELECT COALESCE(SUM(e.totalCostMad), 0)
        FROM EnergyConsumption e
        WHERE e.timestamp >= :start AND e.timestamp < :end
    """)
    BigDecimal sumCostBetween(@Param("start") LocalDateTime start,
                              @Param("end") LocalDateTime end);

    @Query("""
        SELECT COALESCE(SUM(e.totalPowerKw), 0)
        FROM EnergyConsumption e
        WHERE e.timestamp >= :start AND e.timestamp < :end
    """)
    BigDecimal sumPowerBetween(@Param("start") LocalDateTime start,
                               @Param("end") LocalDateTime end);

    // ✅ Used by CostSavingsScheduler
    @Query("""
        SELECT COALESCE(SUM(e.totalCostMad), 0)
        FROM EnergyConsumption e
        WHERE e.timestamp >= :start AND e.timestamp < :end
          AND e.withOptimization = true
    """)
    BigDecimal sumActualCostBetween(@Param("start") LocalDateTime start,
                                    @Param("end") LocalDateTime end);

    @Query("""
        SELECT COALESCE(SUM(e.totalCostMad), 0)
        FROM EnergyConsumption e
        WHERE e.timestamp >= :start AND e.timestamp < :end
          AND e.withOptimization = false
    """)
    BigDecimal sumBaselineCostBetween(@Param("start") LocalDateTime start,
                                      @Param("end") LocalDateTime end);
}
