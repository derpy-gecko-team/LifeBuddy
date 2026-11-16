package com.derpygecko.lifebuddy.ai;

import com.derpygecko.lifebuddy.ai.dto.AiProcessRequest;
import com.derpygecko.lifebuddy.ai.dto.AiProcessResponse;
import com.derpygecko.lifebuddy.ai.dto.JevCheckRequest;
import com.derpygecko.lifebuddy.ai.dto.JevCheckResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class AiClientService {

    private final RestClient aiRestClient;

    public AiClientService(RestClient aiRestClient) {
        this.aiRestClient = aiRestClient;
    }

    public JevCheckResponse checkInputWithJev(JevCheckRequest request) {
        return post("/internal/v1/jev-check", request, JevCheckResponse.class);
    }

    public AiProcessResponse processTurn(AiProcessRequest request) {
        return post("/internal/v1/process-turn", request, AiProcessResponse.class);
    }

    private <T> T post(String path, Object body, Class<T> responseType) {
        try {
            T response = aiRestClient.post()
                    .uri(path)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(responseType);
            if (response == null) {
                throw new AiServiceException("Empty response from AI service at " + path, null);
            }
            return response;
        } catch (RestClientException e) {
            throw new AiServiceException("AI service call failed at " + path, e);
        }
    }
}