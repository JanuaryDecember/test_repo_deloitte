CREATE TABLE employee (
    id            BIGSERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    service_line  VARCHAR(100),
    role_family   VARCHAR(100),
    contact_info  VARCHAR(255),  -- Teams/email handle for match reveal
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

