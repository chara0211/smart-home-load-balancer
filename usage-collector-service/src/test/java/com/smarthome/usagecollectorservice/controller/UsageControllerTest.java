package com.smarthome.usagecollectorservice.controller;

import com.smarthome.usagecollectorservice.model.HomeUsage;
import com.smarthome.usagecollectorservice.repository.HomeUsageRepository;
import com.smarthome.usagecollectorservice.service.UsageAggregationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.Sort;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UsageController.class)
class UsageControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UsageAggregationService usageAggregationService;

    @MockBean
    private HomeUsageRepository homeUsageRepository;

    @Test
    void testGetCurrentUsage() throws Exception {
        // Given
        Map<String, Double> devices = new HashMap<>();
        devices.put("tv-1", 0.12);
        devices.put("aircon-1", 0.8);
        
        when(usageAggregationService.getCurrentTotalPowerKw()).thenReturn(0.92);
        when(usageAggregationService.getLastDevicePower()).thenReturn(devices);

        // When & Then
        mockMvc.perform(get("/usage/current"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.totalPowerKw").value(0.92))
                .andExpect(jsonPath("$.deviceCount").value(2))
                .andExpect(jsonPath("$.devices.tv-1").value(0.12))
                .andExpect(jsonPath("$.devices.aircon-1").value(0.8));
    }

    @Test
    void testGetUsageHistory() throws Exception {
        // Given
        HomeUsage usage1 = new HomeUsage(1L, 0.92, Instant.now());
        HomeUsage usage2 = new HomeUsage(2L, 1.2, Instant.now().minusSeconds(60));
        List<HomeUsage> history = Arrays.asList(usage1, usage2);
        
        when(homeUsageRepository.findAll(any(Sort.class))).thenReturn(history);

        // When & Then
        mockMvc.perform(get("/usage/history"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].totalPowerKw").value(0.92))
                .andExpect(jsonPath("$[1].totalPowerKw").value(1.2));
    }

    @Test
    void testGetUsageHistoryWithLimit() throws Exception {
        // Given
        HomeUsage usage1 = new HomeUsage(1L, 0.92, Instant.now());
        List<HomeUsage> history = Arrays.asList(usage1);
        
        when(homeUsageRepository.findAll(any(Sort.class))).thenReturn(history);

        // When & Then
        mockMvc.perform(get("/usage/history?limit=50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void testGetDeviceUsage() throws Exception {
        // Given
        Map<String, Double> devices = new HashMap<>();
        devices.put("tv-1", 0.12);
        devices.put("aircon-1", 0.8);
        
        when(usageAggregationService.getLastDevicePower()).thenReturn(devices);

        // When & Then
        mockMvc.perform(get("/usage/devices"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.tv-1").value(0.12))
                .andExpect(jsonPath("$.aircon-1").value(0.8));
    }

    @Test
    void testSaveSnapshot() throws Exception {
        // Given
        when(usageAggregationService.getCurrentTotalPowerKw()).thenReturn(0.92);
        doNothing().when(usageAggregationService).saveCurrentSnapshot();

        // When & Then
        mockMvc.perform(post("/usage/save"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("Snapshot sauvegardé avec succès"))
                .andExpect(jsonPath("$.totalPowerKw").value(0.92));
        
        verify(usageAggregationService, times(1)).saveCurrentSnapshot();
    }
}

