package com.derpygecko.lifebuddy.auth;

import com.derpygecko.lifebuddy.user.User;
import com.derpygecko.lifebuddy.user.UserService;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Service
public class AuthService {
    private final AuthenticationManager authenticationManager;
    private final PasswordEncoder passwordEncoder;
    private final UserService userService;
    private final JwtService jwtService;

    public AuthService(
            AuthenticationManager authenticationManager,
            PasswordEncoder passwordEncoder,
            UserService userService,
            JwtService jwtService
    ) {
        this.authenticationManager = authenticationManager;
        this.passwordEncoder = passwordEncoder;
        this.userService = userService;
        this.jwtService = jwtService;
    }

    public AuthResponse register(RegisterRequestDTO request) {
        String username = request.getUsername().strip();
        String email = normalizeEmail(request.getEmail());
        validateBcryptPasswordLength(request.getPassword());

        if (userService.existsByEmail(email) || userService.existsByUsername(username)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username or email is already registered");
        }

        User user;
        try {
            user = userService.createUser(username, email, passwordEncoder.encode(request.getPassword()));
        } catch (DataIntegrityViolationException exception) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username or email is already registered", exception);
        }

        return createResponse(user);
    }

    public AuthResponse login(LoginRequestDTO request) {
        String email = normalizeEmail(request.getEmail());
        if (request.getPassword().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        }

        try {
            String authenticatedEmail = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, request.getPassword())
            ).getName();
            User user = userService.findByEmail(authenticatedEmail)
                    .orElseThrow(() -> new AuthenticationServiceException("Authenticated user could not be loaded"));
            return createResponse(user);
        } catch (AuthenticationException exception) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        }
    }

    private AuthResponse createResponse(User user) {
        return new AuthResponse(jwtService.generateToken(user.getEmail()), user.getId(), user.getUsername());
    }

    private String normalizeEmail(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }

    private void validateBcryptPasswordLength(String password) {
        if (password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Password must not exceed 72 UTF-8 bytes"
            );
        }
    }
}
