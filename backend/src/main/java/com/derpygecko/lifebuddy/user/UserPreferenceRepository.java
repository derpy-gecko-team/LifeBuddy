package com.derpygecko.lifebuddy.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserPreferenceRepository extends JpaRepository<UserPreference, Long> {
    List<UserPreference> findAllByUserIdOrderByPreferenceTypeAscValueAsc(Long userId);
    Optional<UserPreference> findByUserIdAndPreferenceTypeAndValue(
            Long userId,
            PreferenceType preferenceType,
            String value
    );
}
