CREATE TABLE journeys (
                          id BIGSERIAL PRIMARY KEY,
                          user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                          title VARCHAR(255) NOT NULL,
                          tile_type VARCHAR(100) NOT NULL DEFAULT 'GENERAL',
                          coord_q INT NOT NULL,
                          coord_r INT NOT NULL,
                          status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
                          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          CONSTRAINT uq_user_hex UNIQUE (user_id, coord_q, coord_r)
);

CREATE TABLE quests (
                        id BIGSERIAL PRIMARY KEY,
                        journey_id BIGINT NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
                        title VARCHAR(255) NOT NULL,
                        category VARCHAR(100),
                        status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
                        started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        completed_at TIMESTAMP
);