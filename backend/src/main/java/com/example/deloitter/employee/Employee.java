package com.example.deloitter.employee;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * JPA entity for the employee table.
 * ManyToMany relationships (interests, competencies) are intentionally omitted here;
 * they will be added when F-01 Phase 3 is completed.
 */
@Entity
@Table(name = "employee")
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(name = "service_line")
    private String serviceLine;

    @Column(name = "role_family")
    private String roleFamily;

    @Column(name = "contact_info")
    private String contactInfo;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public String getEmail() { return email; }
    public String getPasswordHash() { return passwordHash; }
    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }
    public String getServiceLine() { return serviceLine; }
    public String getRoleFamily() { return roleFamily; }
    public String getContactInfo() { return contactInfo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
