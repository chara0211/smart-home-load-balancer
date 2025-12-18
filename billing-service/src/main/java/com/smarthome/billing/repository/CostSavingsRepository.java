package com.smarthome.billing.repository;

import com.smarthome.billing.model.CostSavings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CostSavingsRepository extends JpaRepository<CostSavings, UUID> {
    
    Optional<CostSavings> findByDate(LocalDate date);
    
    List<CostSavings> findByDateBetweenOrderByDateDesc(LocalDate start, LocalDate end);
    
    @Query("SELECT SUM(c.savingsMad) FROM CostSavings c WHERE c.date >= :startDate")
    BigDecimal sumSavingsSince(@Param("startDate") LocalDate startDate);
    
    @Query("SELECT SUM(c.peaksPrevented) FROM CostSavings c WHERE c.date >= :startDate")
    Integer sumPeaksPreventedSince(@Param("startDate") LocalDate startDate);
    
    @Query("SELECT SUM(c.automationActions) FROM CostSavings c WHERE c.date >= :startDate")
    Integer sumAutomationActionsSince(@Param("startDate") LocalDate startDate);
}
