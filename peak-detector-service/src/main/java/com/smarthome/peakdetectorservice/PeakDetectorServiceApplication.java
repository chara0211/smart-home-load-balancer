package com.smarthome.peakdetectorservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling   // pour @Scheduled
public class PeakDetectorServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(PeakDetectorServiceApplication.class, args);
	}
}
