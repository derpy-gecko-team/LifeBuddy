package com.derpygecko.lifebuddy.user;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class UserMapper {
    public UserProfileDTO toDTO(User user) {
        if (user == null) {
            return null;
        }
        return new UserProfileDTO(
                user.getId(),
                user.getUsername(),
                user.getEmail()
        );
    }
}
