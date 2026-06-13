package com.example.deloitter.swipe;

import com.example.deloitter.employee.Employee;
import com.example.deloitter.employee.EmployeeRepository;
import com.example.deloitter.match.MatchResult;
import com.example.deloitter.match.MatchService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class DiscoverService {

    private final EmployeeRepository employeeRepository;
    private final SwipeRepository swipeRepository;
    private final CompatibilityService compatibilityService;
    private final MatchService matchService;

    public DiscoverService(
            EmployeeRepository employeeRepository,
            SwipeRepository swipeRepository,
            CompatibilityService compatibilityService,
            MatchService matchService) {
        this.employeeRepository = employeeRepository;
        this.swipeRepository = swipeRepository;
        this.compatibilityService = compatibilityService;
        this.matchService = matchService;
    }

    /**
     * Returns the ranked candidate stack for the authenticated employee.
     * Already-swiped candidates are excluded. Score is used for ordering only —
     * it is NOT included in the returned DTOs (privacy guardrail).
     */
    @Transactional(readOnly = true)
    public List<CandidateCard> getStack(Employee me) {
        // Re-fetch me with interests + competencies eagerly loaded (avoids LazyInitializationException
        // when the entity was resolved outside this transaction in the controller layer).
        Employee meLoaded = employeeRepository.findWithCollectionsById(me.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Employee not found"));

        // Collect already-swiped candidate IDs
        Set<Long> swiped = swipeRepository.findBySwiperId(meLoaded.getId()).stream()
                .map(EmployeeSwipe::getCandidateId)
                .collect(Collectors.toSet());

        // Fetch all employees (with collections) except self, excluding already-swiped
        List<Employee> candidates = employeeRepository.findAllWithCollections().stream()
                .filter(e -> !e.getId().equals(meLoaded.getId()))
                .filter(e -> !swiped.contains(e.getId()))
                .collect(Collectors.toList());

        // Compute score for each candidate, sort descending, secondary sort by ID for stability
        record Scored(Employee employee, int score) {}

        return candidates.stream()
                .map(c -> new Scored(c, compatibilityService.computeScore(meLoaded, c)))
                .sorted(Comparator.comparingInt(Scored::score).reversed()
                        .thenComparingLong(s -> s.employee().getId()))
                .map(s -> {
                    Employee c = s.employee();
                    return new CandidateCard(
                            c.getId(),
                            c.getFirstName(),
                            c.getLastName(),
                            CandidateCard.computeInitials(c.getFirstName(), c.getLastName()),
                            c.getRoleFamily(),
                            c.getServiceLine(),
                            c.getContactInfo(),
                            compatibilityService.sharedInterests(meLoaded, c),
                            compatibilityService.sharedCompetencies(meLoaded, c)
                    );
                })
                .collect(Collectors.toList());
    }

    /**
     * Records a swipe decision (like or pass).
     * When {@code liked} is true, also checks for a mutual match and returns it if found.
     * Returns an empty Optional for passes or one-sided likes (privacy guardrail).
     * Throws 409 if the user has already swiped this candidate.
     * Throws 400 if candidateId is invalid or equals the swiper's own ID.
     */
    @Transactional
    public Optional<MatchResult> recordSwipe(Employee me, Long candidateId, boolean liked) {
        if (candidateId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "candidateId is required");
        }
        if (candidateId.equals(me.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cannot swipe on yourself");
        }
        Employee candidate = employeeRepository.findById(candidateId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Candidate not found: " + candidateId));
        if (swipeRepository.existsBySwiperIdAndCandidateId(me.getId(), candidateId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Already swiped on candidate: " + candidateId);
        }

        swipeRepository.save(new EmployeeSwipe(me.getId(), candidateId, liked));

        if (liked) {
            return matchService.detectAndCreateMatch(me, candidate);
        }
        return Optional.empty();
    }
}

