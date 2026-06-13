package com.example.deloitter.swipe;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SwipeRepository extends JpaRepository<EmployeeSwipe, SwipeId> {

    List<EmployeeSwipe> findBySwiperId(Long swiperId);

    boolean existsBySwiperIdAndCandidateId(Long swiperId, Long candidateId);

    /** Returns true if swiperId liked candidateId (liked = true). */
    boolean existsBySwiperIdAndCandidateIdAndLikedTrue(Long swiperId, Long candidateId);
}

