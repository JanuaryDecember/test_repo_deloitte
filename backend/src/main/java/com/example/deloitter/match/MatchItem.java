package com.example.deloitter.match;

import java.util.List;

/**
 * DTO for an entry in the user's matches list (GET /api/matches).
 * Contains frozen score (from match time) and current shared attributes.
 */
public record MatchItem(
        Long matchId,
        Long matchedEmployeeId,
        String firstName,
        String lastName,
        String initials,
        String roleFamily,
        String serviceLine,
        String contactInfo,
        int score,
        List<String> sharedInterests,
        List<String> sharedCompetencies) {}

