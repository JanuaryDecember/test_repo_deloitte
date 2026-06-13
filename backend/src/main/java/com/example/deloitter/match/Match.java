package com.example.deloitter.match;

import com.example.deloitter.employee.Employee;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "employee_match")
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "employee_1_id", nullable = false)
    private Long employee1Id;

    @Column(name = "employee_2_id", nullable = false)
    private Long employee2Id;

    @Column(nullable = false)
    private int score;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_1_id", insertable = false, updatable = false)
    private Employee employee1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_2_id", insertable = false, updatable = false)
    private Employee employee2;

    protected Match() {}

    @PrePersist
    private void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    /**
     * Factory method that creates a Match with canonical ID ordering (smaller ID first).
     */
    public static Match create(Long empA, Long empB, int score) {
        Match m = new Match();
        if (empA < empB) {
            m.employee1Id = empA;
            m.employee2Id = empB;
        } else {
            m.employee1Id = empB;
            m.employee2Id = empA;
        }
        m.score = score;
        return m;
    }

    public Long getId() {
        return id;
    }

    public Long getEmployee1Id() {
        return employee1Id;
    }

    public Long getEmployee2Id() {
        return employee2Id;
    }

    public int getScore() {
        return score;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public Employee getEmployee1() {
        return employee1;
    }

    public Employee getEmployee2() {
        return employee2;
    }
}

