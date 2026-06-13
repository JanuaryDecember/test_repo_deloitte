CREATE TABLE employee_swipe (
    swiper_id    BIGINT NOT NULL REFERENCES employee(id),
    candidate_id BIGINT NOT NULL REFERENCES employee(id),
    liked        BOOLEAN NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (swiper_id, candidate_id),
    CHECK (swiper_id <> candidate_id)
);
CREATE INDEX idx_swipe_swiper ON employee_swipe(swiper_id);

