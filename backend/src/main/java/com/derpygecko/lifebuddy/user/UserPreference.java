package com.derpygecko.lifebuddy.user;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;


@Entity
@Table(name="user_preferences")
@Getter
@Setter
@NoArgsConstructor
public class UserPreference {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name="user_id", nullable=false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name="preference_type", nullable=false)
    private PreferenceType preferenceType;

    @Column(nullable=false)
    private String value;

    public UserPreference(Long userId, PreferenceType preferenceType, String value) {
        this.userId = userId;
        this.preferenceType = preferenceType;
        this.value = value;
    }
}
