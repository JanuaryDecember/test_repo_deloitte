package com.example.deloitter.employee;

import com.example.deloitter.catalog.Competency;
import com.example.deloitter.catalog.Interest;
import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "employee")
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 255)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    @Column(name = "service_line", length = 100)
    private String serviceLine;

    @Column(name = "role_family", length = 100)
    private String roleFamily;

    @Column(name = "contact_info", length = 255)
    private String contactInfo;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "employee_interest",
            joinColumns = @JoinColumn(name = "employee_id"),
            inverseJoinColumns = @JoinColumn(name = "interest_id")
    )
    private Set<Interest> interests = new HashSet<>();

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "employee_competency",
            joinColumns = @JoinColumn(name = "employee_id"),
            inverseJoinColumns = @JoinColumn(name = "competency_id")
    )
    private Set<Competency> competencies = new HashSet<>();

    protected Employee() {}

    @PrePersist
    private void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    // Getters

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getServiceLine() {
        return serviceLine;
    }

    public String getRoleFamily() {
        return roleFamily;
    }

    public String getContactInfo() {
        return contactInfo;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public Set<Interest> getInterests() {
        return interests;
    }

    public Set<Competency> getCompetencies() {
        return competencies;
    }

    // Setters

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public void setServiceLine(String serviceLine) {
        this.serviceLine = serviceLine;
    }

    public void setRoleFamily(String roleFamily) {
        this.roleFamily = roleFamily;
    }

    public void setContactInfo(String contactInfo) {
        this.contactInfo = contactInfo;
    }

    public void setInterests(Set<Interest> interests) {
        this.interests = interests;
    }

    public void setCompetencies(Set<Competency> competencies) {
        this.competencies = competencies;
    }
}

