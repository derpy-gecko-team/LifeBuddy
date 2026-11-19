package com.derpygecko.lifebuddy.map;

import com.derpygecko.lifebuddy.ai.AiClientService;
import com.derpygecko.lifebuddy.ai.dto.*;
import com.derpygecko.lifebuddy.user.User;
import com.derpygecko.lifebuddy.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MapService {

    private static final int[][] HEX_DIRECTIONS = {
            {1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, -1}, {-1, 1}
    };

    private static final List<String> DEFAULT_TILE_TYPES = List.of(
            "FOREST", "LIBRARY", "GYM", "MOUNTAIN", "GARDEN"
    );

    private final JourneyRepository journeyRepository;
    private final QuestRepository questRepository;
    private final UserRepository userRepository;
    private final AiClientService aiClientService;

    public List<MapDtos.HexTileDto> getUserMap(Long userId) {
        return journeyRepository.findByUserId(userId).stream()
                .map(this::toHexTileDto)
                .toList();
    }

    public MapDtos.JourneyDetailDto getJourneyDetails(Long journeyId) {
        Journey journey = journeyRepository.findById(journeyId)
                .orElseThrow(() -> new IllegalArgumentException("Journey not found"));

        List<MapDtos.QuestDto> active = new ArrayList<>();
        List<MapDtos.QuestDto> completed = new ArrayList<>();

        for (Quest q : journey.getQuests()) {
            MapDtos.QuestDto dto = new MapDtos.QuestDto(
                    q.getId(), q.getTitle(), q.getCategory(), q.getStatus(),
                    q.getStartedAt(), q.getCompletedAt(), q.getDurationMinutes()
            );
            if ("COMPLETED".equals(q.getStatus())) {
                completed.add(dto);
            } else {
                active.add(dto);
            }
        }

        return new MapDtos.JourneyDetailDto(
                journey.getId(), journey.getTitle(), journey.getTileType(),
                journey.getCoordQ(), journey.getCoordR(), journey.getStatus(),
                active, completed
        );
    }

    @Transactional
    public MapDtos.ChatResponse handleUserMessage(Long userId, String message) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        List<ActiveJourney> activeJourneys = journeyRepository.findByUserId(userId).stream()
                .map(j -> new ActiveJourney(j.getId(), j.getTitle(), j.getTileType()))
                .toList();

        List<ActiveQuest> activeQuests = questRepository.findByJourneyUserIdAndStatus(userId, "ACTIVE").stream()
                .map(q -> new ActiveQuest(q.getId(), q.getTitle()))
                .toList();

        AiProcessRequest aiRequest = new AiProcessRequest(
                message,
                "GENERAL",
                new UserContext(List.of(), List.of(), List.of()),
                activeQuests,
                DEFAULT_TILE_TYPES,
                activeJourneys
        );

        AiProcessResponse aiResponse = aiClientService.processTurn(aiRequest);

        // 1. Marchează quest-urile completate detectate de AI
        for (Long completedId : aiResponse.questsCompletedIds()) {
            questRepository.findById(completedId).ifPresent(q -> {
                q.setStatus("COMPLETED");
                q.setCompletedAt(Instant.now());
                questRepository.save(q);
            });
        }

        // 2. Creează un Journey nou sau adaugă quest-uri la unul existent
        Journey affectedJourney = null;
        if (aiResponse.targetJourneyId() != null) {
            affectedJourney = journeyRepository.findById(aiResponse.targetJourneyId()).orElse(null);
        } else if (aiResponse.journeyTitle() != null && !aiResponse.journeyTitle().isBlank()) {
            int[] coords = findNextFreeHex(userId);
            affectedJourney = new Journey();
            affectedJourney.setUser(user);
            affectedJourney.setTitle(aiResponse.journeyTitle());
            affectedJourney.setTileType(aiResponse.selectedTileType() != null ? aiResponse.selectedTileType() : "GENERAL");
            affectedJourney.setCoordQ(coords[0]);
            affectedJourney.setCoordR(coords[1]);
        }

        if (affectedJourney != null) {
            for (QuestToCreate qtc : aiResponse.questsToCreate()) {
                Quest quest = new Quest();
                quest.setJourney(affectedJourney);
                quest.setTitle(qtc.title());
                quest.setCategory(qtc.category());
                affectedJourney.getQuests().add(quest);
            }
            affectedJourney = journeyRepository.save(affectedJourney);
        }

        return new MapDtos.ChatResponse(
                aiResponse.guideReply(),
                affectedJourney != null ? toHexTileDto(affectedJourney) : null
        );
    }

    @Transactional
    public void completeQuest(Long questId) {
        Quest quest = questRepository.findById(questId)
                .orElseThrow(() -> new IllegalArgumentException("Quest not found"));
        quest.setStatus("COMPLETED");
        quest.setCompletedAt(Instant.now());
        questRepository.save(quest);
    }

    private int[] findNextFreeHex(Long userId) {
        List<Journey> existing = journeyRepository.findByUserId(userId);
        if (existing.isEmpty()) {
            return new int[]{0, 0};
        }

        Set<String> occupied = new HashSet<>();
        for (Journey j : existing) {
            occupied.add(j.getCoordQ() + "," + j.getCoordR());
        }

        int[] best = null;
        int bestDist = Integer.MAX_VALUE;
        for (Journey j : existing) {
            for (int[] dir : HEX_DIRECTIONS) {
                int nq = j.getCoordQ() + dir[0];
                int nr = j.getCoordR() + dir[1];
                if (!occupied.contains(nq + "," + nr)) {
                    int dist = Math.max(Math.abs(nq), Math.max(Math.abs(nr), Math.abs(nq + nr)));
                    if (dist < bestDist) {
                        bestDist = dist;
                        best = new int[]{nq, nr};
                    }
                }
            }
        }
        return best;
    }

    private MapDtos.HexTileDto toHexTileDto(Journey j) {
        int total = j.getQuests().size();
        int done = (int) j.getQuests().stream().filter(q -> "COMPLETED".equals(q.getStatus())).count();
        return new MapDtos.HexTileDto(
                j.getId(), j.getTitle(), j.getTileType(),
                j.getCoordQ(), j.getCoordR(), j.getStatus(), total, done
        );
    }

}