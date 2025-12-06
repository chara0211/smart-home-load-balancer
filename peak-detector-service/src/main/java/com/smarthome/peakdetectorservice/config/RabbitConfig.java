package com.smarthome.peakdetectorservice.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String ALERTS_EXCHANGE = "alerts.exchange";
    public static final String ALERTS_PEAK_QUEUE = "alerts.peak.queue";

    // ===== Exchange pour les alertes de pic =====
    @Bean
    public TopicExchange alertsExchange() {
        return new TopicExchange(ALERTS_EXCHANGE);
    }

    // ===== Queue consommée par l'Optimizer =====
    @Bean
    public Queue alertsPeakQueue() {
        return new Queue(ALERTS_PEAK_QUEUE, true);
    }

    @Bean
    public Binding alertsPeakBinding() {
        return BindingBuilder
                .bind(alertsPeakQueue())
                .to(alertsExchange())
                .with("peak.detected");
    }

    // ===== Convertisseur JSON pour RabbitMQ =====
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    // RabbitTemplate qui utilise le converter JSON
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory,
                                         MessageConverter jsonMessageConverter) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jsonMessageConverter);
        return template;
    }

    // Listener container factory qui utilise aussi le JSON
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
