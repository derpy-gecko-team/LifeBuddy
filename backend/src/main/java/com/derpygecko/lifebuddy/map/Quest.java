package com.derpygecko.lifebuddy.map;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Duration;
import java.time.Instant;

@Entity
@Table(name = "quests")
@Getter
@Setter
@NoArgsConstructor
public class Quest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "journey_id", nullable = false)
    private Journey journey;

    @Column(nullable = false)
    private String title;

    private String category;

    @Column(nullable = false)
    private String status = "ACTIVE";

    @Column(name = "started_at", nullable = false, updatable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "completed_at")
    private Instant completedAt;

    public Long getDurationMinutes() {
        if (completedAt == null) return null;
        return Duration.between(startedAt, completedAt).toMinutes();
    }
}