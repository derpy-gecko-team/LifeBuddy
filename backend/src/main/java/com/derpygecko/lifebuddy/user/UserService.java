package com.derpygecko.lifebuddy.user;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class UserService implements UserDetailsService {
    private final UserRepository userRepository;
    private final UserPreferenceRepository userPreferenceRepository;

    public UserService(UserRepository userRepository, UserPreferenceRepository userPreferenceRepository) {
        this.userRepository = userRepository;
        this.userPreferenceRepository = userPreferenceRepository;
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmailIgnoreCase(normalizeEmail(email));
    }

    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    public boolean existsByEmail(String email) {
        return userRepository.existsByEmailIgnoreCase(normalizeEmail(email));
    }

    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    public User createUser(String username, String email, String passwordHash) {
        User user = new User(username, normalizeEmail(email), passwordHash);
        return userRepository.saveAndFlush(user);
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        if (user.getPasswordHash() == null || user.getPasswordHash().isBlank()) {
            throw new UsernameNotFoundException("User not found");
        }
        return org.springframework.security.core.userdetails.User.withUsername(user.getEmail())
                .password(user.getPasswordHash())
                .authorities("ROLE_USER")
                .build();
    }

    private String normalizeEmail(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }

    public List<UserPreference> getUserPreferencesByUserId(Long userId) {
        return userPreferenceRepository.findAllByUserIdOrderByPreferenceTypeAscValueAsc(userId);
    }

    public Map<String, List<String>> getUserContextPayload(Long userId) {
        Map<String, List<String>> payload = new LinkedHashMap<>();
        for (PreferenceType type : PreferenceType.values()) {
            payload.put(type.name(), new ArrayList<>());
        }

        for (UserPreference preference : getUserPreferencesByUserId(userId)) {
            payload.get(preference.getPreferenceType().name()).add(preference.getValue());
        }
        return payload;
    }

    @Transactional
    public void addUserPreference(Long userId, PreferenceType preferenceType, String value) {
        if (userPreferenceRepository
                .findByUserIdAndPreferenceTypeAndValue(userId, preferenceType, value)
                .isEmpty()) {
            userPreferenceRepository.save(new UserPreference(userId, preferenceType, value));
        }
    }

    @Transactional
    public void removeUserPreference(Long userId, PreferenceType preferenceType, String value) {
        userPreferenceRepository
                .findByUserIdAndPreferenceTypeAndValue(userId, preferenceType, value)
                .ifPresent(userPreferenceRepository::delete);
    }
}
