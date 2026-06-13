package com.example.deloitter.swipe;

import java.util.List;

/**
 * DTO representing a candidate card in the discover stack.
 * Deliberately excludes the compatibility score — it is used only for ranking
 * and must not be exposed to the client until a mutual match occurs (privacy guardrail).
 */
public record CandidateCard(
        Long id,
        String firstName,
        String lastName,
        String initials,
        String roleFamily,
        String serviceLine,
        String contactInfo,
        List<String> sharedInterests,
        List<String> sharedCompetencies
) {
    public static String computeInitials(String firstName, String lastName) {
        String f = (firstName != null && !firstName.isEmpty()) ? String.valueOf(firstName.charAt(0)).toUpperCase() : "";
        String l = (lastName != null && !lastName.isEmpty()) ? String.valueOf(lastName.charAt(0)).toUpperCase() : "";
        return f + l;
    }
}

