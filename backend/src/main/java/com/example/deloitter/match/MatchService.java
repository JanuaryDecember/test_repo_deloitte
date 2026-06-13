package com.example.deloitter.match;

import com.example.deloitter.employee.Employee;
import com.example.deloitter.employee.EmployeeRepository;
import com.example.deloitter.swipe.CompatibilityService;
import com.example.deloitter.swipe.SwipeRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class MatchService {

    private final MatchRepository matchRepository;
    private final SwipeRepository swipeRepository;
    private final EmployeeRepository employeeRepository;
    private final CompatibilityService compatibilityService;

    public MatchService(
            MatchRepository matchRepository,
            SwipeRepository swipeRepository,
            EmployeeRepository employeeRepository,
            CompatibilityService compatibilityService) {
        this.matchRepository = matchRepository;
        this.swipeRepository = swipeRepository;
        this.employeeRepository = employeeRepository;
        this.compatibilityService = compatibilityService;
    }

    /**
     * Called when {@code me} has just liked {@code candidate}.
     * Checks if {@code candidate} also liked {@code me} (reverse swipe).
     * If so, creates (or fetches existing) a Match row and returns a MatchResult DTO.
     * Returns empty Optional when no mutual match exists.
     *
     * Privacy guardrail: this method is only reachable on a like — a pass never
     * triggers match detection, and the result is never exposed for non-mutual swipes.
     */
    @Transactional
    public Optional<MatchResult> detectAndCreateMatch(Employee me, Employee candidate) {
        // Check whether candidate already liked me
        if (!swipeRepository.existsBySwiperIdAndCandidateIdAndLikedTrue(
                candidate.getId(), me.getId())) {
            return Optional.empty();
        }

        Long minId = Math.min(me.getId(), candidate.getId());
        Long maxId = Math.max(me.getId(), candidate.getId());

        // Load both employees with collections for score computation
        Employee meLoaded = employeeRepository.findWithCollectionsById(me.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Employee not found"));
        Employee candidateLoaded = employeeRepository.findWithCollectionsById(candidate.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Candidate not found"));

        // Idempotency: return existing match if already created
        if (matchRepository.existsByEmployee1IdAndEmployee2Id(minId, maxId)) {
            Match existing = matchRepository.findByEmployee1IdAndEmployee2Id(minId, maxId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Match inconsistency"));
            return Optional.of(buildMatchResult(existing, meLoaded, candidateLoaded));
        }

        int score = compatibilityService.computeScore(meLoaded, candidateLoaded);

        Match match;
        try {
            match = matchRepository.save(Match.create(me.getId(), candidate.getId(), score));
        } catch (DataIntegrityViolationException e) {
            // Race condition backstop: another thread inserted first
            match = matchRepository.findByEmployee1IdAndEmployee2Id(minId, maxId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Match inconsistency after conflict"));
        }

        return Optional.of(buildMatchResult(match, meLoaded, candidateLoaded));
    }

    /**
     * Returns all confirmed mutual matches for {@code me}, most recent first.
     * Shared attributes are re-computed from current selections; the score is the
     * frozen value stored at match time.
     */
    @Transactional(readOnly = true)
    public List<MatchItem> getMatches(Employee me) {
        List<Match> matches = matchRepository.findByEmployeeId(me.getId());

        Employee meLoaded = employeeRepository.findWithCollectionsById(me.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Employee not found"));

        return matches.stream()
                .sorted(Comparator.comparing(Match::getCreatedAt).reversed())
                .map(match -> {
                    Long otherId = match.getEmployee1Id().equals(me.getId())
                            ? match.getEmployee2Id()
                            : match.getEmployee1Id();
                    Employee other = employeeRepository.findWithCollectionsById(otherId)
                            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Employee not found: " + otherId));

                    List<String> sharedInterests = compatibilityService.sharedInterests(meLoaded, other);
                    List<String> sharedCompetencies = compatibilityService.sharedCompetencies(meLoaded, other);
                    String initials = MatchResult.computeInitials(other.getFirstName(), other.getLastName());

                    return new MatchItem(
                            match.getId(),
                            other.getId(),
                            other.getFirstName(),
                            other.getLastName(),
                            initials,
                            other.getRoleFamily(),
                            other.getServiceLine(),
                            other.getContactInfo(),
                            match.getScore(),
                            sharedInterests,
                            sharedCompetencies);
                })
                .collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private MatchResult buildMatchResult(Match match, Employee me, Employee candidate) {
        List<String> sharedInterests = compatibilityService.sharedInterests(me, candidate);
        List<String> sharedCompetencies = compatibilityService.sharedCompetencies(me, candidate);
        String shareSummary = MatchResult.computeShareSummary(sharedInterests, sharedCompetencies);
        String initials = MatchResult.computeInitials(candidate.getFirstName(), candidate.getLastName());

        return new MatchResult(
                match.getId(),
                candidate.getId(),
                candidate.getFirstName(),
                candidate.getLastName(),
                initials,
                candidate.getRoleFamily(),
                candidate.getServiceLine(),
                candidate.getContactInfo(),
                match.getScore(),
                sharedInterests,
                sharedCompetencies,
                shareSummary);
    }
}

