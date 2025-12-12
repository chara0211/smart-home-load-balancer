package com.smarthome.usagecollectorservice.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String DEVICE_USAGE_QUEUE = "device.usage.queue";
    public static final String DEVICE_EVENTS_EXCHANGE = "device.events.exchange";

    @Bean
    public Queue usageQueue() {
        return new Queue(DEVICE_USAGE_QUEUE, true);
    }

    @Bean
    public TopicExchange deviceEventsExchange() {
        return new TopicExchange(DEVICE_EVENTS_EXCHANGE);
    }

    @Bean
    public Binding usageBinding(Queue usageQueue, TopicExchange deviceEventsExchange) {
        // doit matcher la routing key utilisée par le simulateur : "device.usage.xxx"
        return BindingBuilder.bind(usageQueue)
                .to(deviceEventsExchange)
                .with("device.usage.#");
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory
    ) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(jsonMessageConverter());
        return factory;
    }
}
