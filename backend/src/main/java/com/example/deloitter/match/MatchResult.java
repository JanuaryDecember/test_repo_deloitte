package com.example.deloitter.match;

import java.util.ArrayList;
import java.util.List;

/**
 * DTO returned inside the swipe response when a mutual match is detected.
 * Includes score, contact info, and shared-attribute summary.
 * Only revealed when BOTH users have liked each other — never otherwise.
 */
public record MatchResult(
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
        List<String> sharedCompetencies,
        String shareSummary) {

    /** Compute two-letter uppercase initials from first and last name. */
    public static String computeInitials(String firstName, String lastName) {
        char f = (firstName != null && !firstName.isEmpty()) ? firstName.charAt(0) : '?';
        char l = (lastName != null && !lastName.isEmpty()) ? lastName.charAt(0) : '?';
        return (("" + f) + l).toUpperCase();
    }

    /**
     * Build a share summary like "Machine Learning, Startups, Travel +2 more"
     * from the combined shared interests and competencies list.
     * Shows up to 3 attributes; appends "+N more" if there are additional ones.
     */
    public static String computeShareSummary(List<String> sharedInterests, List<String> sharedCompetencies) {
        List<String> all = new ArrayList<>();
        all.addAll(sharedInterests);
        all.addAll(sharedCompetencies);
        if (all.isEmpty()) {
            return "";
        }
        if (all.size() <= 3) {
            return String.join(", ", all);
        }
        String first3 = String.join(", ", all.subList(0, 3));
        int more = all.size() - 3;
        return first3 + " +" + more + " more";
    }
}

