package com.example.deloitter.auth;

import com.example.deloitter.employee.EmployeeRepository;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class AuthUserDetailsService implements UserDetailsService {

    private final EmployeeRepository employeeRepository;

    public AuthUserDetailsService(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return employeeRepository.findByEmail(email)
                .map(employee -> User.withUsername(employee.getEmail())
                        .password(employee.getPasswordHash())
                        .roles("USER")
                        .build())
                .orElseThrow(() -> new UsernameNotFoundException(
                        "No employee with email: " + email));
    }
}
