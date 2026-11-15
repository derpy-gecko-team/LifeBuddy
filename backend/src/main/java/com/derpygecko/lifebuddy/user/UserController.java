package com.derpygecko.lifebuddy.user;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    @GetMapping("/preferences")
    public List<UserPreferenceDTO> getUserPreferences(
            @RequestParam(required = false) Long userId
    ) {
        Long authenticatedUserId = requireOwnUserId(userId);
        return userService.getUserPreferencesByUserId(authenticatedUserId).stream()
                .map(preference -> new UserPreferenceDTO(
                        preference.getPreferenceType(),
                        preference.getValue()
                ))
                .toList();
    }

    @PutMapping("/preferences")
    public ResponseEntity<Void> addUserPreference(
            @RequestParam(required = false) Long userId,
            @Valid @RequestBody UserPreferenceRequest request
    ) {
        userService.addUserPreference(
                requireOwnUserId(userId),
                request.preferenceType(),
                request.value()
        );
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/preferences")
    public ResponseEntity<Void> removeUserPreference(
            @RequestParam(required = false) Long userId,
            @Valid @RequestBody UserPreferenceRequest request
    ) {
        userService.removeUserPreference(
                requireOwnUserId(userId),
                request.preferenceType(),
                request.value()
        );
        return ResponseEntity.noContent().build();
    }

    private Long requireOwnUserId(Long requestedUserId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authentication required");
        }
        if (requestedUserId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "userId is required");
        }

        User user = userService.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Authenticated user no longer exists"
                ));
        if (!user.getId().equals(requestedUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Cannot access another user's preferences");
        }
        return user.getId();
    }
}
