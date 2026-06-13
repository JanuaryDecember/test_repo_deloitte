package com.example.deloitter.profile;

import com.example.deloitter.catalog.Competency;
import com.example.deloitter.catalog.CompetencyRepository;
import com.example.deloitter.catalog.Interest;
import com.example.deloitter.catalog.InterestRepository;
import com.example.deloitter.employee.Employee;
import com.example.deloitter.employee.EmployeeRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class ProfileService {

    private final EmployeeRepository employeeRepository;
    private final InterestRepository interestRepository;
    private final CompetencyRepository competencyRepository;

    public ProfileService(
            EmployeeRepository employeeRepository,
            InterestRepository interestRepository,
            CompetencyRepository competencyRepository) {
        this.employeeRepository = employeeRepository;
        this.interestRepository = interestRepository;
        this.competencyRepository = competencyRepository;
    }

    @Transactional(readOnly = true)
    public ProfileResponse getProfile() {
        Employee employee = authenticatedEmployee();
        String initials = String.valueOf(Character.toUpperCase(employee.getFirstName().charAt(0)))
                + Character.toUpperCase(employee.getLastName().charAt(0));
        return new ProfileResponse(
                employee.getId(),
                employee.getFirstName(),
                employee.getLastName(),
                employee.getEmail(),
                employee.getServiceLine(),
                employee.getRoleFamily(),
                employee.getContactInfo(),
                initials
        );
    }

    @Transactional(readOnly = true)
    public SelectionsResponse getSelections() {
        Employee employee = authenticatedEmployee();
        List<Long> interestIds = employee.getInterests().stream()
                .map(Interest::getId)
                .toList();
        List<Long> competencyIds = employee.getCompetencies().stream()
                .map(Competency::getId)
                .toList();
        return new SelectionsResponse(interestIds, competencyIds);
    }

    @Transactional
    public SelectionsResponse updateSelections(SelectionsRequest request) {
        Employee employee = authenticatedEmployee();

        List<Long> requestedInterestIds = request.interestIds() == null ? List.of() : request.interestIds();
        List<Long> requestedCompetencyIds = request.competencyIds() == null ? List.of() : request.competencyIds();

        Set<Long> distinctInterestIds = new HashSet<>(requestedInterestIds);
        Set<Long> distinctCompetencyIds = new HashSet<>(requestedCompetencyIds);

        List<Interest> foundInterests = interestRepository.findAllById(distinctInterestIds);
        if (foundInterests.size() != distinctInterestIds.size()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "One or more interest IDs are invalid");
        }

        List<Competency> foundCompetencies = competencyRepository.findAllById(distinctCompetencyIds);
        if (foundCompetencies.size() != distinctCompetencyIds.size()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "One or more competency IDs are invalid");
        }

        employee.setInterests(new HashSet<>(foundInterests));
        employee.setCompetencies(new HashSet<>(foundCompetencies));
        employeeRepository.save(employee);

        List<Long> savedInterestIds = foundInterests.stream().map(Interest::getId).toList();
        List<Long> savedCompetencyIds = foundCompetencies.stream().map(Competency::getId).toList();
        return new SelectionsResponse(savedInterestIds, savedCompetencyIds);
    }

    private Employee authenticatedEmployee() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Employee not found"));
    }
}
