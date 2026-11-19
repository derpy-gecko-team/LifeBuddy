package com.derpygecko.lifebuddy.map;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/map")
@RequiredArgsConstructor
public class MapController {

    private final MapService mapService;

    @GetMapping("/{userId}")
    public List<MapDtos.HexTileDto> getMap(@PathVariable Long userId) {
        return mapService.getUserMap(userId);
    }

    @GetMapping("/journeys/{journeyId}")
    public MapDtos.JourneyDetailDto getJourneyDetails(@PathVariable Long journeyId) {
        return mapService.getJourneyDetails(journeyId);
    }

    @PostMapping("/chat")
    public MapDtos.ChatResponse chat(@RequestBody MapDtos.ChatRequest request) {
        return mapService.handleUserMessage(request.userId(), request.message());
    }

    @PatchMapping("/quests/{questId}/complete")
    public void completeQuest(@PathVariable Long questId) {
        mapService.completeQuest(questId);
    }

}