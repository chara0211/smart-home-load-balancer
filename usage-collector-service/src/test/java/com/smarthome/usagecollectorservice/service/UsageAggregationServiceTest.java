package com.smarthome.usagecollectorservice.service;

import com.smarthome.usagecollectorservice.model.DeviceUsageEvent;
import com.smarthome.usagecollectorservice.model.HomeUsage;
import com.smarthome.usagecollectorservice.repository.HomeUsageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UsageAggregationServiceTest {

    @Mock
    private HomeUsageRepository homeUsageRepository;

    @InjectMocks
    private UsageAggregationService usageAggregationService;

    @BeforeEach
    void setUp() {
        // Reset si nécessaire
    }

    @Test
    void testOnDeviceUsage_ShouldUpdateDevicePower() {
        // Given
        DeviceUsageEvent event = new DeviceUsageEvent("tv-1", 0.12);

        // When
        usageAggregationService.onDeviceUsage(event);

        // Then
        Map<String, Double> devicePower = usageAggregationService.getLastDevicePower();
        assertEquals(0.12, devicePower.get("tv-1"));
        assertEquals(0.12, usageAggregationService.getCurrentTotalPowerKw());
    }

    @Test
    void testOnDeviceUsage_ShouldRecalculateTotal() {
        // Given
        DeviceUsageEvent event1 = new DeviceUsageEvent("tv-1", 0.12);
        DeviceUsageEvent event2 = new DeviceUsageEvent("aircon-1", 0.8);
        DeviceUsageEvent event3 = new DeviceUsageEvent("oven-1", 1.6);

        // When
        usageAggregationService.onDeviceUsage(event1);
        usageAggregationService.onDeviceUsage(event2);
        usageAggregationService.onDeviceUsage(event3);

        // Then
        double total = usageAggregationService.getCurrentTotalPowerKw();
        assertEquals(2.52, total, 0.01); // 0.12 + 0.8 + 1.6 = 2.52
    }

    @Test
    void testOnDeviceUsage_ShouldPersistToDatabase() {
        // Given
        DeviceUsageEvent event = new DeviceUsageEvent("tv-1", 0.12);
        when(homeUsageRepository.save(any(HomeUsage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // When
        usageAggregationService.onDeviceUsage(event);

        // Then
        ArgumentCaptor<HomeUsage> captor = ArgumentCaptor.forClass(HomeUsage.class);
        verify(homeUsageRepository, times(1)).save(captor.capture());
        
        HomeUsage saved = captor.getValue();
        assertEquals(0.12, saved.getTotalPowerKw());
        assertNotNull(saved.getTimestamp());
    }

    @Test
    void testOnDeviceUsage_ShouldUpdateExistingDevice() {
        // Given
        DeviceUsageEvent event1 = new DeviceUsageEvent("tv-1", 0.12);
        DeviceUsageEvent event2 = new DeviceUsageEvent("tv-1", 0.15); // Mise à jour

        // When
        usageAggregationService.onDeviceUsage(event1);
        usageAggregationService.onDeviceUsage(event2);

        // Then
        Map<String, Double> devicePower = usageAggregationService.getLastDevicePower();
        assertEquals(0.15, devicePower.get("tv-1"));
        assertEquals(0.15, usageAggregationService.getCurrentTotalPowerKw());
    }

    @Test
    void testSaveCurrentSnapshot() {
        // Given
        DeviceUsageEvent event = new DeviceUsageEvent("tv-1", 0.12);
        usageAggregationService.onDeviceUsage(event);
        when(homeUsageRepository.save(any(HomeUsage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // When
        usageAggregationService.saveCurrentSnapshot();

        // Then
        verify(homeUsageRepository, times(2)).save(any(HomeUsage.class)); // Une fois dans onDeviceUsage, une fois dans saveCurrentSnapshot
    }
}

