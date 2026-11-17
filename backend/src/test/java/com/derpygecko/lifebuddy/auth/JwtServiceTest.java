package com.derpygecko.lifebuddy.auth;

import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class JwtServiceTest {
    private final JwtService jwtService = new JwtService(
            Base64.getEncoder().encodeToString(new byte[32]),
            60_000
    );

    @Test
    void generatedTokenContainsTheEmailSubject() {
        String token = jwtService.generateToken("user@example.com");

        assertEquals("user@example.com", jwtService.extractEmail(token));
    }

    @Test
    void invalidTokenIsRejected() {
        assertThrows(JwtException.class, () -> jwtService.extractEmail("not-a-jwt"));
    }
}
