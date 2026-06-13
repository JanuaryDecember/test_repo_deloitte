package com.example.deloitter.controller;

import com.example.deloitter.model.MatchRequestDto;
import com.example.deloitter.model.MatchResponseDto;
import com.example.deloitter.service.MatchingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/matching")
@RequiredArgsConstructor
public class MatchingController {

    private final MatchingService matchingService;

    @PostMapping("/best-match")
    public ResponseEntity<MatchResponseDto> findBestMatch(
            @RequestBody MatchRequestDto request) {

        return ResponseEntity.ok(
                matchingService.findBestMatch(request));
    }
}
