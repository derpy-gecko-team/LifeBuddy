package com.derpygecko.lifebuddy.map;

import com.derpygecko.lifebuddy.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "journeys", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "coord_q", "coord_r"}))
@Getter
@Setter
@NoArgsConstructor
public class Journey {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(name = "tile_type", nullable = false)
    private String tileType = "GENERAL";

    @Column(name = "coord_q", nullable = false)
    private int coordQ;

    @Column(name = "coord_r", nullable = false)
    private int coordR;

    @Column(nullable = false)
    private String status = "ACTIVE";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @OneToMany(mappedBy = "journey", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Quest> quests = new ArrayList<>();
}