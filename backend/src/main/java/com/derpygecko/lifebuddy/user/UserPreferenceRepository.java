package com.derpygecko.lifebuddy.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserPreferenceRepository extends JpaRepository<UserPreference, Long> {
    public List<UserPreference> findAllByUserId(Long userId);
}
