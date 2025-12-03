package com.smarthome.optimizerservice.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    // Exchange pour recevoir les alertes de pic
    public static final String ALERTS_EXCHANGE = "alerts.exchange";
    
    // Exchange pour envoyer les commandes aux appareils
    public static final String CONTROL_COMMANDS_EXCHANGE = "control.commands.exchange";
    
    // Queue pour recevoir les alertes de pic
    public static final String PEAK_ALERTS_QUEUE = "peak.alerts.queue";

    @Bean
    public TopicExchange alertsExchange() {
        return new TopicExchange(ALERTS_EXCHANGE);
    }

    @Bean
    public DirectExchange controlCommandsExchange() {
        return new DirectExchange(CONTROL_COMMANDS_EXCHANGE);
    }

    @Bean
    public Queue peakAlertsQueue() {
        return new Queue(PEAK_ALERTS_QUEUE, true);
    }

    @Bean
    public Binding peakAlertsBinding() {
        return BindingBuilder.bind(peakAlertsQueue())
                .to(alertsExchange())
                .with("peak.detected");
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(jsonMessageConverter());
        return factory;
    }
}
