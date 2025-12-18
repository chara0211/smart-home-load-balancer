package com.smarthome.billing.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String USAGE_EVENTS_QUEUE = "usage.events";

    //  match existing publisher setup
    public static final String USAGE_EVENTS_EXCHANGE = "device.events.exchange";
    public static final String USAGE_EVENTS_ROUTING_KEY = "device.usage.#";

    @Bean
    public Queue usageEventsQueue() {
        return QueueBuilder.durable(USAGE_EVENTS_QUEUE).build();
    }

    @Bean
    public TopicExchange exchange() {
        return new TopicExchange(USAGE_EVENTS_EXCHANGE);
    }

    @Bean
    public Binding usageEventsBinding(Queue usageEventsQueue, TopicExchange exchange) {
        return BindingBuilder
                .bind(usageEventsQueue)
                .to(exchange)
                .with(USAGE_EVENTS_ROUTING_KEY);
    }

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory cf) {
        RabbitTemplate template = new RabbitTemplate(cf);
        template.setMessageConverter(messageConverter());
        return template;
    }
}


