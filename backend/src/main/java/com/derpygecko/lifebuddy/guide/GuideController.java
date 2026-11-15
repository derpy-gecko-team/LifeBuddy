package com.derpygecko.lifebuddy.guide;

import com.derpygecko.lifebuddy.guide.dto.InteractionResponse;
import com.derpygecko.lifebuddy.guide.dto.UserSpeechRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/guide")
public class GuideController {

    // TODO: replace with the authenticated user's id once JWT auth is merged
    private static final Long DEMO_USER_ID = 1L;

    private final GuideService guideService;

    public GuideController(GuideService guideService) {
        this.guideService = guideService;
    }

    @PostMapping("/interact")
    public InteractionResponse interact(@Valid @RequestBody UserSpeechRequest request) {
        return guideService.interact(DEMO_USER_ID, request.userText());
    }
}