package com.example.deloitter.swipe;

import java.io.Serializable;
import java.util.Objects;

public class SwipeId implements Serializable {

    private Long swiperId;
    private Long candidateId;

    public SwipeId() {}

    public SwipeId(Long swiperId, Long candidateId) {
        this.swiperId = swiperId;
        this.candidateId = candidateId;
    }

    public Long getSwiperId() {
        return swiperId;
    }

    public void setSwiperId(Long swiperId) {
        this.swiperId = swiperId;
    }

    public Long getCandidateId() {
        return candidateId;
    }

    public void setCandidateId(Long candidateId) {
        this.candidateId = candidateId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof SwipeId)) return false;
        SwipeId that = (SwipeId) o;
        return Objects.equals(swiperId, that.swiperId)
                && Objects.equals(candidateId, that.candidateId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(swiperId, candidateId);
    }
}

