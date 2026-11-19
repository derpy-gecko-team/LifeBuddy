package com.derpygecko.lifebuddy.map;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface QuestRepository extends JpaRepository<Quest, Long> {
    List<Quest> findByJourneyUserIdAndStatus(Long userId, String status);
}