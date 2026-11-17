package com.derpygecko.lifebuddy.guide;

import com.derpygecko.lifebuddy.guide.dto.InteractionResponse;
import com.derpygecko.lifebuddy.guide.dto.UserSpeechRequest;
import com.derpygecko.lifebuddy.user.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/guide")
public class GuideController {

    private final GuideService guideService;
    private final UserService userService;

    public GuideController(GuideService guideService, UserService userService) {
        this.guideService = guideService;
        this.userService = userService;
    }

    @PostMapping("/interact")
    public InteractionResponse interact(@Valid @RequestBody UserSpeechRequest request,
                                        Authentication authentication) {
        Long userId = userService.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"))
                .getId();
        return guideService.interact(userId, request.userText());
    }
}