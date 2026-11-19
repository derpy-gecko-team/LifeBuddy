package com.derpygecko.lifebuddy.ai.dto;

import java.util.List;

public record AiProcessResponse(String guideReply,
                                List<QuestToCreate> questsToCreate,
                                List<Long> questsCompletedIds,
                                String selectedTileType,
                                String journeyTitle,
                                Long targetJourneyId) {

    public AiProcessResponse {
        questsToCreate = questsToCreate == null ? List.of() : questsToCreate;
        questsCompletedIds = questsCompletedIds == null ? List.of() : questsCompletedIds;
    }
}