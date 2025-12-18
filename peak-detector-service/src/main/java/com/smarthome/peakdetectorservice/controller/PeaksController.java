package com.smarthome.peakdetectorservice.controller;

import com.smarthome.peakdetectorservice.model.PeakEvent;
import com.smarthome.peakdetectorservice.service.PeakDetectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/peaks")
@RequiredArgsConstructor
public class PeaksController {

    private final PeakDetectionService peakDetectionService;

    @GetMapping("/recent")
    public List<PeakEvent> recent(@RequestParam(defaultValue = "20") int limit) {
        return peakDetectionService.getRecentPeaks(limit);
    }
}
