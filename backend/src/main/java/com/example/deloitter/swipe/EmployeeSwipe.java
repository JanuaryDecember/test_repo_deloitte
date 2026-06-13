package com.example.deloitter.swipe;

import com.example.deloitter.employee.Employee;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "employee_swipe")
@IdClass(SwipeId.class)
public class EmployeeSwipe {

    @Id
    @Column(name = "swiper_id")
    private Long swiperId;

    @Id
    @Column(name = "candidate_id")
    private Long candidateId;

    @Column(nullable = false)
    private boolean liked;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "swiper_id", insertable = false, updatable = false)
    private Employee swiper;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "candidate_id", insertable = false, updatable = false)
    private Employee candidate;

    protected EmployeeSwipe() {}

    public EmployeeSwipe(Long swiperId, Long candidateId, boolean liked) {
        this.swiperId = swiperId;
        this.candidateId = candidateId;
        this.liked = liked;
    }

    @PrePersist
    private void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    public Long getSwiperId() {
        return swiperId;
    }

    public Long getCandidateId() {
        return candidateId;
    }

    public boolean isLiked() {
        return liked;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public Employee getSwiper() {
        return swiper;
    }

    public Employee getCandidate() {
        return candidate;
    }
}

