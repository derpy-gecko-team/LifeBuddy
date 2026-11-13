package com.derpygecko.lifebuddy.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class LoginRequestDTO {
    @NotBlank(message = "Email cannot be blank")
    @Email(message = "Must be a valid email address")
    String email;

    @NotBlank(message = "Password cannot be blank")
    @Size(max = 72, message = "Password is too long")
    String password;
}
