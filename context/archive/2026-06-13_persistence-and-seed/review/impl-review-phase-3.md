> **Archived:** 2026-06-13 | Change ID: `persistence-and-seed` | Roadmap ID: `F-01`

---
change_id: "persistence-and-seed"
phase: 3
phase_name: "JPA Entities & Repositories"
reviewed: 2026-06-13
verdict: PASS WITH NOTES
findings_total: 4
critical: 0
major: 0
minor: 2
suggestions: 2
fixes_applied: 2
---

# Phase 3 Review: JPA Entities & Repositories

## Summary

All eight plan checklist items were implemented correctly. Entity column mappings are exact matches to the V1–V3 Flyway migrations, join table and FK column names align perfectly, and repository interfaces are well-formed. Two minor issues were fixed: `plan.md` status and checklist items were updated to reflect the completed implementation, and `id`-based `equals`/`hashCode` was added to `Interest` and `Competency` to ensure safe set-intersection behaviour for the future scoring slice (S-04).

## Plan Faithfulness

| Checklist item | Status |
|---|---|
| `com.example.deloitter.employee` package created | ✅ |
| `com.example.deloitter.catalog` package created | ✅ |
| `Employee.java` — `@Entity`, all 9 fields, `@ManyToMany` interests + competencies | ✅ |
| `Interest.java` — `@Entity`, `id`, `name` | ✅ |
| `Competency.java` — `@Entity`, `id`, `name` | ✅ |
| `EmployeeRepository` extends `JpaRepository<Employee, Long>`, `findByEmail` | ✅ |
| `InterestRepository` extends `JpaRepository<Interest, Long>` | ✅ |
| `CompetencyRepository` extends `JpaRepository<Competency, Long>` | ✅ |

## Findings

### 🟡 Minor

| # | Dimension | File / Location | Finding | Resolution |
|---|-----------|-----------------|---------|------------|
| 1 | Plan Faithfulness | `context/changes/persistence-and-seed/plan.md` | Plan `status` was still `revised` and Phase 3 checklist items remained `- [ ]` despite implementation being staged | Fixed — status set to `implemented`, all Phase 3 items checked off |
| 2 | Technical Correctness | `catalog/Interest.java`, `catalog/Competency.java` | `Interest` and `Competency` used default `Object` identity for `equals`/`hashCode`. Set-intersection (`retainAll`) across JPA sessions or different entity manager contexts would silently fail — a risk for the S-04 scoring algorithm | Fixed — added `id`-based `equals` with constant `hashCode` (standard Hibernate-safe pattern) to both entities |

### 🔵 Suggestions

| # | Dimension | File / Location | Finding | Resolution |
|---|-----------|-----------------|---------|------------|
| 1 | Technical Correctness | `Employee.java` lines 43, 51 | `FetchType.LAZY` on `@ManyToMany` is correct best practice but requires all downstream service methods that access `interests`/`competencies` to be inside a `@Transactional` boundary | No code change — noted for Phase 5 and scoring slice authors |
| 2 | Convention Adherence | `Employee.java` | `Employee` entity also lacks `equals`/`hashCode`; lower priority since employees aren't put into sets for scoring, but consistent entity hygiene | Deferred — not needed until swipe/match entities reference employees in collections |

## Guardrail Compliance

| Guardrail | Status | Evidence |
|-----------|--------|----------|
| No rejection signals | N/A | Domain model phase only; no swipe/match tables or endpoints |
| Explainable score | N/A | No scoring logic in this phase |
| Score hidden while swiping | N/A | No scoring logic in this phase |

## Verdict

**PASS WITH NOTES** — All plan items implemented correctly. Column and join-table mappings are exact matches to the Flyway schema. Two minor fixes applied: plan documentation updated to reflect implementation state, and `equals`/`hashCode` added to catalog entities to protect future scoring set-intersection logic.

