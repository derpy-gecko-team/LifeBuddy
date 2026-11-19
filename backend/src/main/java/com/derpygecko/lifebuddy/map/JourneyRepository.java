package com.derpygecko.lifebuddy.map;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JourneyRepository extends JpaRepository<Journey, Long> {
    List<Journey> findByUserId(Long userId);
}