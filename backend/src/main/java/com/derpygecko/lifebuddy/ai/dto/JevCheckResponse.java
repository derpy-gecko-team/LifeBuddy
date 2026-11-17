package com.derpygecko.lifebuddy.ai.dto;

public record JevCheckResponse(boolean isSafe,
                               boolean isRelevant,
                               String intent,
                               String reason) {
}