package com.smarthome.optimizerservice.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    // Exchange sur lequel PeakDetector envoie les alertes
    public static final String ALERTS_EXCHANGE = "alerts.exchange";

    // Queue sur laquelle Optimizer écoute les peaks
    public static final String PEAK_ALERTS_QUEUE = "peak.alerts.queue";

    // Exchange déjà utilisé pour envoyer des commandes aux devices
    public static final String CONTROL_COMMANDS_EXCHANGE = "control.commands.exchange";

    @Bean
    public TopicExchange alertsExchange() {
        return new TopicExchange(ALERTS_EXCHANGE);
    }

    @Bean
    public Queue peakAlertsQueue() {
        return new Queue(PEAK_ALERTS_QUEUE, true);
    }

    @Bean
    public Binding peakAlertsBinding() {
        // On route les messages envoyés avec routingKey = "peak.detected"
        // vers la queue peak.alerts.queue
        return BindingBuilder.bind(peakAlertsQueue())
                .to(alertsExchange())
                .with("peak.detected");
    }

    // ====== JSON converter pour PeakEvent & DeviceCommand ======

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    // Pour que @RabbitListener utilise le converter JSON
    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory,
            MessageConverter jsonMessageConverter
    ) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(jsonMessageConverter);
        return factory;
    }
}
