package com.derpygecko.lifebuddy.ai.dto;

import java.util.List;

public record AiProcessRequest(String userText,
                               String intent,
                               UserContext userContext,
                               List<ActiveQuest> activeQuests,
                               List<String> availableTileTypes,
                               List<ActiveJourney> activeJourneys) {
}