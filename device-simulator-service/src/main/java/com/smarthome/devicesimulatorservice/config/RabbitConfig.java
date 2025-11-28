package com.smarthome.devicesimulatorservice.config;

import org.springframework.amqp.core.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    // Exchanges
    public static final String DEVICE_EVENTS_EXCHANGE = "device.events.exchange";
    public static final String CONTROL_COMMANDS_EXCHANGE = "control.commands.exchange";

    // Queue pour recevoir les commandes
    public static final String DEVICE_CONTROL_QUEUE = "device.control.queue";

    @Bean
    public TopicExchange deviceEventsExchange() {
        return new TopicExchange(DEVICE_EVENTS_EXCHANGE);
    }

    @Bean
    public DirectExchange controlCommandsExchange() {
        return new DirectExchange(CONTROL_COMMANDS_EXCHANGE);
    }

    @Bean
    public Queue deviceControlQueue() {
        return new Queue(DEVICE_CONTROL_QUEUE, true);
    }

    @Bean
    public Binding deviceControlBinding() {
        // toutes les clés device.command.*
        return BindingBuilder.bind(deviceControlQueue())
                .to(controlCommandsExchange())
                .with("device.command.#");
    }
}
