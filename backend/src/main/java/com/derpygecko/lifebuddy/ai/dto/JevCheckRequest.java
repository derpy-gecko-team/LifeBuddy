package com.derpygecko.lifebuddy.ai.dto;

import java.util.List;

public record JevCheckRequest(String userText,
                              List<String> activeGoals) {
}