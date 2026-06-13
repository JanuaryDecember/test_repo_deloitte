package com.example.deloitter.match;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MatchRepository extends JpaRepository<Match, Long> {

    @Query("SELECT m FROM Match m WHERE m.employee1Id = :id OR m.employee2Id = :id")
    List<Match> findByEmployeeId(@Param("id") Long id);

    boolean existsByEmployee1IdAndEmployee2Id(Long employee1Id, Long employee2Id);

    Optional<Match> findByEmployee1IdAndEmployee2Id(Long employee1Id, Long employee2Id);
}

