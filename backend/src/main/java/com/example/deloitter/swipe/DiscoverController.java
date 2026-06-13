package com.example.deloitter.swipe;

import com.example.deloitter.employee.Employee;
import com.example.deloitter.employee.EmployeeRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/discover")
public class DiscoverController {

    private final DiscoverService discoverService;
    private final EmployeeRepository employeeRepository;

    public DiscoverController(DiscoverService discoverService, EmployeeRepository employeeRepository) {
        this.discoverService = discoverService;
        this.employeeRepository = employeeRepository;
    }

    /**
     * GET /api/discover/stack
     * Returns the ranked candidate stack for the authenticated user.
     * The response intentionally omits the compatibility score (privacy guardrail).
     */
    @GetMapping("/stack")
    public ResponseEntity<List<CandidateCard>> getStack() {
        Employee me = resolveAuthenticatedEmployee();
        List<CandidateCard> stack = discoverService.getStack(me);
        return ResponseEntity.ok(stack);
    }

    /**
     * POST /api/discover/swipe
     * Records a like or pass decision for a candidate.
     * Response includes a non-null {@code match} field only when a mutual match was just detected.
     * Returns 200 on success, 409 if already swiped, 400 if candidateId is invalid.
     */
    @PostMapping("/swipe")
    public ResponseEntity<?> swipe(@RequestBody SwipeRequest request) {
        Employee me = resolveAuthenticatedEmployee();
        try {
            var matchResult = discoverService.recordSwipe(me, request.candidateId(), request.liked());
            return ResponseEntity.ok(new SwipeResponse(true, matchResult.orElse(null)));
        } catch (ResponseStatusException ex) {
            return ResponseEntity.status(ex.getStatusCode())
                    .body(Map.of("error", ex.getReason()));
        }
    }

    private Employee resolveAuthenticatedEmployee() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authenticated employee not found"));
    }
}

