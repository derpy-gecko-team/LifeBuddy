package com.derpygecko.lifebuddy.ai;

import com.derpygecko.lifebuddy.ai.dto.AiProcessRequest;
import com.derpygecko.lifebuddy.ai.dto.AiProcessResponse;
import com.derpygecko.lifebuddy.ai.dto.JevCheckRequest;
import com.derpygecko.lifebuddy.ai.dto.JevCheckResponse;
import com.derpygecko.lifebuddy.ai.dto.UserContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class AiClientServiceTest {

    private MockRestServiceServer server;
    private AiClientService service;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://ai");
        server = MockRestServiceServer.bindTo(builder).build();
        service = new AiClientService(builder.build());
    }

    @Test
    void jevCheckParsesResponse() {
        server.expect(requestTo("http://ai/internal/v1/jev-check"))
                .andExpect(method(HttpMethod.POST))
                .andRespond(withSuccess("""
                        {"isSafe": true, "isRelevant": true, "intent": "COMPLETE_QUEST", "reason": "ok"}
                        """, MediaType.APPLICATION_JSON));

        JevCheckResponse response = service.checkInputWithJev(
                new JevCheckRequest("Did 40 minutes of cardio", List.of("Get fit")));

        assertThat(response.isSafe()).isTrue();
        assertThat(response.isRelevant()).isTrue();
        assertThat(response.intent()).isEqualTo("COMPLETE_QUEST");
    }

    @Test
    void processTurnDefaultsMissingListsToEmpty() {
        server.expect(requestTo("http://ai/internal/v1/process-turn"))
                .andRespond(withSuccess("""
                        {"guideReply": "Nice work!"}
                        """, MediaType.APPLICATION_JSON));

        AiProcessResponse response = service.processTurn(new AiProcessRequest(
                "Did 40 minutes of cardio", "COMPLETE_QUEST",
                new UserContext(List.of(), List.of(), List.of()), List.of(), List.of()));

        assertThat(response.guideReply()).isEqualTo("Nice work!");
        assertThat(response.questsToCreate()).isEmpty();
        assertThat(response.questsCompletedIds()).isEmpty();
    }

    @Test
    void serverErrorBecomesAiServiceException() {
        server.expect(requestTo("http://ai/internal/v1/jev-check"))
                .andRespond(withServerError());

        assertThatThrownBy(() -> service.checkInputWithJev(new JevCheckRequest("hi", List.of())))
                .isInstanceOf(AiServiceException.class);
    }
}