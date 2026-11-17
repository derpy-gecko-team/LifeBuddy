package com.derpygecko.lifebuddy.user;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UserControllerTest {
    private static final String EMAIL = "user@example.com";
    private static final Long USER_ID = 42L;

    private final UserService userService = mock(UserService.class);
    private final UserController userController = new UserController(userService);

    @BeforeEach
    void authenticateUser() {
        User user = new User();
        user.setId(USER_ID);
        when(userService.findByEmail(EMAIL)).thenReturn(Optional.of(user));
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(EMAIL, null, List.of())
        );
    }

    @AfterEach
    void clearAuthentication() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void getPreferencesUsesAuthenticatedUser() {
        userController.getUserPreferences();

        verify(userService).getUserPreferencesByUserId(USER_ID);
    }

    @Test
    void addPreferenceUsesAuthenticatedUser() {
        UserPreferenceRequest request = new UserPreferenceRequest(PreferenceType.LIKE, "coffee");

        assertEquals(204, userController.addUserPreference(request).getStatusCode().value());

        verify(userService).addUserPreference(USER_ID, PreferenceType.LIKE, "coffee");
    }

    @Test
    void removePreferenceUsesAuthenticatedUser() {
        UserPreferenceRequest request = new UserPreferenceRequest(PreferenceType.DISLIKE, "rain");

        assertEquals(204, userController.removeUserPreference(request).getStatusCode().value());

        verify(userService).removeUserPreference(USER_ID, PreferenceType.DISLIKE, "rain");
    }
}
