package com.derpygecko.lifebuddy.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UserPreferenceRequest(
        @NotNull PreferenceType preferenceType,
        @NotBlank @Size(max = 255) String value
) {
}
