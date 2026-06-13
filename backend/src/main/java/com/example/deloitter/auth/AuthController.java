package com.example.deloitter.auth;

import com.example.deloitter.employee.Employee;
import com.example.deloitter.employee.EmployeeRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final SecurityContextRepository securityContextRepository;
    private final EmployeeRepository employeeRepository;

    public AuthController(
            AuthenticationManager authenticationManager,
            SecurityContextRepository securityContextRepository,
            EmployeeRepository employeeRepository) {
        this.authenticationManager = authenticationManager;
        this.securityContextRepository = securityContextRepository;
        this.employeeRepository = employeeRepository;
    }

    /**
     * POST /api/auth/login
     * Verifies email+password, establishes an HTTP session, and returns the authenticated user.
     * Explicit SecurityContextRepository.saveContext() is required in Spring Security 6+/7.x
     * because the framework no longer auto-saves programmatic authentication.
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(
            @RequestBody LoginRequest request,
            HttpServletRequest servletRequest,
            HttpServletResponse servletResponse) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.email(), request.password())
            );
            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(authentication);
            SecurityContextHolder.setContext(context);
            securityContextRepository.saveContext(context, servletRequest, servletResponse);

            Employee employee = employeeRepository.findByEmail(request.email()).orElseThrow();
            return ResponseEntity.ok(toResponse(employee));
        } catch (AuthenticationException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Invalid credentials"));
        }
    }

    /**
     * GET /api/auth/me
     * Returns the currently authenticated user's profile.
     * Requires an active session; Spring Security returns 401 before this is reached if unauthenticated.
     */
    @GetMapping("/me")
    public ResponseEntity<AuthResponse> me() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElseThrow();
        return ResponseEntity.ok(toResponse(employee));
    }

    /**
     * POST /api/auth/logout
     * Invalidates the HTTP session and clears the SecurityContext.
     */
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        SecurityContextHolder.clearContext();
        return ResponseEntity.noContent().build();
    }

    private AuthResponse toResponse(Employee employee) {
        return new AuthResponse(
                employee.getId(),
                employee.getEmail(),
                employee.getFirstName(),
                employee.getLastName()
        );
    }
}
