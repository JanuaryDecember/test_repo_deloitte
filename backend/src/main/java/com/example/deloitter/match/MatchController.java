package com.example.deloitter.match;

import com.example.deloitter.employee.Employee;
import com.example.deloitter.employee.EmployeeRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/matches")
public class MatchController {

    private final MatchService matchService;
    private final EmployeeRepository employeeRepository;

    public MatchController(MatchService matchService, EmployeeRepository employeeRepository) {
        this.matchService = matchService;
        this.employeeRepository = employeeRepository;
    }

    /**
     * GET /api/matches
     * Returns all confirmed mutual matches for the authenticated user.
     * Always returns 200 with an empty list when no matches exist (never 404).
     * Only mutual matches are included — privacy guardrail enforced at query level.
     */
    @GetMapping
    public ResponseEntity<List<MatchItem>> getMatches() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee me = employeeRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authenticated employee not found"));
        List<MatchItem> matches = matchService.getMatches(me);
        return ResponseEntity.ok(matches);
    }
}

