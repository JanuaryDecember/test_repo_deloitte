package com.example.deloitter.profile;

import java.util.List;

public record SelectionsRequest(List<Long> interestIds, List<Long> competencyIds) {}
