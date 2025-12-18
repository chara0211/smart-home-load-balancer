package com.smarthome.billing.repository;

import com.smarthome.billing.model.MonthlyBill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface MonthlyBillRepository extends JpaRepository<MonthlyBill, UUID> {
    Optional<MonthlyBill> findByMonthAndYear(Integer month, Integer year);
}
