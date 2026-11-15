package com.derpygecko.lifebuddy.guide.dto;

import java.util.List;

public record InteractionResponse(String guideMessage,
                                  List<QuestSummary> updatedQuests,
                                  MapTileSummary newMapTile) {

    public static InteractionResponse messageOnly(String guideMessage) {
        return new InteractionResponse(guideMessage, List.of(), null);
    }
}