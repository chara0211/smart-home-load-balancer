package com.smarthome.usagecollectorservice.repository;

import com.smarthome.usagecollectorservice.model.HomeUsage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HomeUsageRepository extends JpaRepository<HomeUsage, Long> {
}
