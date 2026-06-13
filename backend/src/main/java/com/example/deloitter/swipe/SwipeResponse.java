package com.example.deloitter.swipe;

import com.example.deloitter.match.MatchResult;

/**
 * Response from POST /api/discover/swipe.
 * {@code match} is non-null only when a mutual like was just detected —
 * it is never populated for a pass or a one-sided like (privacy guardrail).
 */
public record SwipeResponse(boolean success, MatchResult match) {}

