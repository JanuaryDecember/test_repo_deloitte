package com.example.deloitter.swipe;

import com.example.deloitter.employee.Employee;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class CompatibilityService {

    /**
     * Computes a Jaccard-index-based compatibility score (0–100) between two employees.
     * Attribute set = interest names + competency names + "sl:" + serviceLine signal.
     * Score is deterministic and explainable: proportional overlap of shared attributes.
     */
    public int computeScore(Employee me, Employee candidate) {
        Set<String> meAttrs = buildAttributeSet(me);
        Set<String> candAttrs = buildAttributeSet(candidate);

        Set<String> intersection = new HashSet<>(meAttrs);
        intersection.retainAll(candAttrs);

        Set<String> union = new HashSet<>(meAttrs);
        union.addAll(candAttrs);

        if (union.isEmpty()) {
            return 0;
        }
        return (int) Math.round(100.0 * intersection.size() / union.size());
    }

    /**
     * Returns the names of interests shared between the two employees.
     */
    public List<String> sharedInterests(Employee me, Employee candidate) {
        Set<String> meInterests = me.getInterests().stream()
                .map(i -> i.getName())
                .collect(Collectors.toSet());
        return candidate.getInterests().stream()
                .map(i -> i.getName())
                .filter(meInterests::contains)
                .sorted()
                .collect(Collectors.toList());
    }

    /**
     * Returns the names of competencies shared between the two employees.
     */
    public List<String> sharedCompetencies(Employee me, Employee candidate) {
        Set<String> meCompetencies = me.getCompetencies().stream()
                .map(c -> c.getName())
                .collect(Collectors.toSet());
        return candidate.getCompetencies().stream()
                .map(c -> c.getName())
                .filter(meCompetencies::contains)
                .sorted()
                .collect(Collectors.toList());
    }

    private Set<String> buildAttributeSet(Employee employee) {
        Set<String> attrs = new HashSet<>();
        employee.getInterests().forEach(i -> attrs.add(i.getName()));
        employee.getCompetencies().forEach(c -> attrs.add(c.getName()));
        if (employee.getServiceLine() != null && !employee.getServiceLine().isBlank()) {
            attrs.add("sl:" + employee.getServiceLine());
        }
        return attrs;
    }
}

