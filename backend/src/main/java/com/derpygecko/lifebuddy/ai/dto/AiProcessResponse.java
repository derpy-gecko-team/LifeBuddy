package com.derpygecko.lifebuddy.ai.dto;

import java.util.List;

public record AiProcessResponse(String guideReply,
                                List<QuestToCreate> questsToCreate,
                                List<Long> questsCompletedIds,
                                String selectedTileType) {

    public AiProcessResponse {
        questsToCreate = questsToCreate == null ? List.of() : questsToCreate;
        questsCompletedIds = questsCompletedIds == null ? List.of() : questsCompletedIds;
    }
}