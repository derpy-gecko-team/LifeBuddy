package com.derpygecko.lifebuddy.guide;

import com.derpygecko.lifebuddy.ai.AiClientService;
import com.derpygecko.lifebuddy.ai.AiServiceException;
import com.derpygecko.lifebuddy.ai.dto.AiProcessResponse;
import com.derpygecko.lifebuddy.ai.dto.JevCheckResponse;
import com.derpygecko.lifebuddy.user.UserService;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class GuideServiceTest {

    private final AiClientService ai = mock(AiClientService.class);
    private final UserService users = mock(UserService.class);

    @Test
    void mockModeNeverCallsAi() {
        GuideService service = new GuideService(ai, users, true);

        assertThat(service.interact(1L, "hello").guideMessage()).startsWith("(mock)");
        verifyNoInteractions(ai);
    }

    @Test
    void irrelevantInputIsRejectedPolitely() {
        GuideService service = new GuideService(ai, users, false);
        when(ai.checkInputWithJev(any())).thenReturn(new JevCheckResponse(true, false, "OTHER", "off-topic"));

        assertThat(service.interact(1L, "what's the weather").guideMessage())
                .isEqualTo(GuideService.NOT_RELEVANT_MESSAGE);
    }

    @Test
    void returnsGuideReplyWhenAiAnswers() {
        GuideService service = new GuideService(ai, users, false);
        when(ai.checkInputWithJev(any())).thenReturn(new JevCheckResponse(true, true, "COMPLETE_QUEST", "ok"));
        when(users.getUserPreferencesByUserId(1L)).thenReturn(List.of());
        when(ai.processTurn(any())).thenReturn(new AiProcessResponse("Great job!", null, null, null));

        assertThat(service.interact(1L, "did cardio").guideMessage()).isEqualTo("Great job!");
    }

    @Test
    void aiFailureGivesFallbackNotError() {
        GuideService service = new GuideService(ai, users, false);
        when(ai.checkInputWithJev(any())).thenThrow(new AiServiceException("down", null));

        assertThat(service.interact(1L, "hi").guideMessage()).isEqualTo(GuideService.FALLBACK_MESSAGE);
    }
}