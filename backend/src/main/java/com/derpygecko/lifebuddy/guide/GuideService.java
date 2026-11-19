package com.derpygecko.lifebuddy.guide;

import com.derpygecko.lifebuddy.ai.AiClientService;
import com.derpygecko.lifebuddy.ai.AiServiceException;
import com.derpygecko.lifebuddy.ai.dto.AiProcessRequest;
import com.derpygecko.lifebuddy.ai.dto.AiProcessResponse;
import com.derpygecko.lifebuddy.ai.dto.JevCheckRequest;
import com.derpygecko.lifebuddy.ai.dto.JevCheckResponse;
import com.derpygecko.lifebuddy.ai.dto.UserContext;
import com.derpygecko.lifebuddy.guide.dto.InteractionResponse;
import com.derpygecko.lifebuddy.user.PreferenceType;
import com.derpygecko.lifebuddy.user.UserPreference;
import com.derpygecko.lifebuddy.user.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GuideService {

    static final String FALLBACK_MESSAGE =
            "Your guide is resting right now. Try again in a moment!";
    static final String NOT_RELEVANT_MESSAGE =
            "I can only help with your goals. Tell me what you worked on or what you want to achieve!";

    private static final Logger log = LoggerFactory.getLogger(GuideService.class);

    private final AiClientService aiClientService;
    private final UserService userService;
    private final boolean mockMode;

    public GuideService(AiClientService aiClientService,
                        UserService userService,
                        @Value("${ai.mock:false}") boolean mockMode) {
        this.aiClientService = aiClientService;
        this.userService = userService;
        this.mockMode = mockMode;
    }

    public InteractionResponse interact(Long userId, String userText) {
        if (mockMode) {
            return InteractionResponse.messageOnly("(mock) Great, I heard: \"" + userText + "\". Keep going!");
        }

        try {
            JevCheckResponse check = aiClientService.checkInputWithJev(
                    new JevCheckRequest(userText, List.of()));
            if (!check.isSafe() || !check.isRelevant()) {
                return InteractionResponse.messageOnly(NOT_RELEVANT_MESSAGE);
            }

            AiProcessResponse result = aiClientService.processTurn(new AiProcessRequest(
                    userText,
                    check.intent(),
                    loadUserContext(userId),
                    List.of(),
                    List.of(),
                    List.of()));

            // Quests and map tiles are wired in once the quest and map services exist.
            return InteractionResponse.messageOnly(result.guideReply());
        } catch (AiServiceException e) {
            log.warn("AI service unavailable, returning fallback reply", e);
            return InteractionResponse.messageOnly(FALLBACK_MESSAGE);
        }
    }

    private UserContext loadUserContext(Long userId) {
        List<UserPreference> preferences = userService.getUserPreferencesByUserId(userId);
        return new UserContext(
                valuesOf(preferences, PreferenceType.LIKE),
                valuesOf(preferences, PreferenceType.DISLIKE),
                List.of());
    }

    private static List<String> valuesOf(List<UserPreference> preferences, PreferenceType type) {
        return preferences.stream()
                .filter(p -> p.getPreferenceType() == type)
                .map(UserPreference::getValue)
                .toList();
    }
}