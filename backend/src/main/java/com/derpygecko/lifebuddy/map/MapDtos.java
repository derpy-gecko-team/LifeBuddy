package com.derpygecko.lifebuddy.map;

import java.time.Instant;
import java.util.List;

public class MapDtos {

    public record HexTileDto(
            Long id,
            String title,
            String tileType,
            int q,
            int r,
            String status,
            int totalQuests,
            int completedQuests
    ) {}

    public record QuestDto(
            Long id,
            String title,
            String category,
            String status,
            Instant startedAt,
            Instant completedAt,
            Long durationMinutes
    ) {}

    public record JourneyDetailDto(
            Long id,
            String title,
            String tileType,
            int q,
            int r,
            String status,
            List<QuestDto> activeQuests,
            List<QuestDto> completedQuests
    ) {}

    public record ChatRequest(Long userId, String message) {}

    public record ChatResponse(String guideReply, HexTileDto updatedTile) {}
}