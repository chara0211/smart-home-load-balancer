package com.smarthome.peakdetectorservice.service;

import com.smarthome.peakdetectorservice.config.RabbitConfig;
import com.smarthome.peakdetectorservice.model.PeakEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class PeakDetectionService {

    private static final double WARNING_THRESHOLD_KW = 4.0;
    private static final double CRITICAL_THRESHOLD_KW = 5.0;

    private final RestTemplate restTemplate;
    private final RabbitTemplate rabbitTemplate;

    // injectée depuis application.properties / application-docker.properties
    @Value("${usage.collector.base-url}")
    private String usageCollectorBaseUrl;

    public PeakDetectionService(RestTemplate restTemplate,
                                RabbitTemplate rabbitTemplate) {
        this.restTemplate = restTemplate;
        this.rabbitTemplate = rabbitTemplate;
    }

    @Scheduled(fixedRate = 5000)
    public void checkForPeaks() {

        Double totalPower = fetchCurrentPowerKw();
        if (totalPower == null) {
            log.warn("No power data from Usage Collector, skipping peak check.");
            return;
        }

        String level = null;
        if (totalPower >= CRITICAL_THRESHOLD_KW) {
            level = "CRITICAL";
        } else if (totalPower >= WARNING_THRESHOLD_KW) {
            level = "WARNING";
        }

        if (level != null) {
            PeakEvent event = new PeakEvent(
                    UUID.randomUUID().toString(),
                    level,
                    totalPower,
                    Instant.now()
            );

            log.info("⚡ Peak detected: level={} totalPower={} kW", level, totalPower);

            rabbitTemplate.convertAndSend(
                    RabbitConfig.ALERTS_EXCHANGE,
                    "peak.detected",
                    event
            );
        } else {
            log.info("No peak: totalPower={} kW", totalPower);
        }
    }

    private Double fetchCurrentPowerKw() {
        try {
            String url = usageCollectorBaseUrl + "/usage/current";

            log.info("Calling Usage Collector at {}", url);

            Map<String, Object> response = restTemplate.getForObject(url, Map.class);

            if (response == null || !response.containsKey("totalPowerKw")) {
                log.warn("Unexpected response from Usage Collector: {}", response);
                return null;
            }

            Number n = (Number) response.get("totalPowerKw");
            double total = n.doubleValue();

            log.info("Current total power from Usage Collector: {} kW", total);
            return total;

        } catch (Exception ex) {
            log.warn("Failed to fetch /usage/current from Usage Collector: {}", ex.getMessage());
            return null;
        }
    }
}
