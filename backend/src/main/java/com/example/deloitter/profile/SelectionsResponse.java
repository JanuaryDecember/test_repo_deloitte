package com.example.deloitter.profile;

import java.util.List;

public record SelectionsResponse(List<Long> interestIds, List<Long> competencyIds) {}
