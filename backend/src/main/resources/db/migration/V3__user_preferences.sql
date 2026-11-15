CREATE TABLE user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preference_type VARCHAR(20) NOT NULL,
    value VARCHAR(255) NOT NULL,
    CONSTRAINT uq_user_preferences UNIQUE (user_id, preference_type, value)
);

CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);