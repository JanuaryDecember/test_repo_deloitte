CREATE TABLE employee_match (
    id             BIGSERIAL PRIMARY KEY,
    employee_1_id  BIGINT NOT NULL REFERENCES employee(id),
    employee_2_id  BIGINT NOT NULL REFERENCES employee(id),
    score          INT NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (employee_1_id, employee_2_id),
    CHECK (employee_1_id < employee_2_id)
);
CREATE INDEX idx_match_emp1 ON employee_match(employee_1_id);
CREATE INDEX idx_match_emp2 ON employee_match(employee_2_id);

