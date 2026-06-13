CREATE TABLE employee_interest (
    employee_id BIGINT NOT NULL REFERENCES employee(id),
    interest_id BIGINT NOT NULL REFERENCES interest(id),
    PRIMARY KEY (employee_id, interest_id)
);

CREATE TABLE employee_competency (
    employee_id   BIGINT NOT NULL REFERENCES employee(id),
    competency_id BIGINT NOT NULL REFERENCES competency(id),
    PRIMARY KEY (employee_id, competency_id)
);

