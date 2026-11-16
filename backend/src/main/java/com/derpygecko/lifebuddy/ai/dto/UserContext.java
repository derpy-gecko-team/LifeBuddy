package com.derpygecko.lifebuddy.ai.dto;

import java.util.List;

public record UserContext(List<String> preferences,
                          List<String> dislikes,
                          List<String> recentCompletedQuests) {
}