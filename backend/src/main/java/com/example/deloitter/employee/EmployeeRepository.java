package com.example.deloitter.employee;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    Optional<Employee> findByEmail(String email);

    /** Fetch a single employee with interests + competencies eagerly loaded. */
    @EntityGraph(attributePaths = {"interests", "competencies"})
    Optional<Employee> findWithCollectionsById(Long id);

    /** Fetch a single employee (by email) with interests + competencies eagerly loaded. */
    @EntityGraph(attributePaths = {"interests", "competencies"})
    @Query("select e from Employee e where e.email = :email")
    Optional<Employee> findWithCollectionsByEmail(String email);

    /** Fetch all employees with interests + competencies eagerly loaded. */
    @EntityGraph(attributePaths = {"interests", "competencies"})
    @Query("select e from Employee e")
    List<Employee> findAllWithCollections();
}
