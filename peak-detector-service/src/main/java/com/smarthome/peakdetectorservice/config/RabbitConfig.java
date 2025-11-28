package com.smarthome.peakdetectorservice.config;


import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String ALERTS_EXCHANGE = "alerts.exchange";

    @Bean
    public TopicExchange alertsExchange() {
        return new TopicExchange(ALERTS_EXCHANGE);
    }
}
