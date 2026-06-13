package com.example.deloitter.service;

import com.example.deloitter.model.MatchRequestDto;
import com.example.deloitter.model.MatchResponseDto;

public interface MatchingService {

    MatchResponseDto findBestMatch(MatchRequestDto request);
}
