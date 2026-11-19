import '../theme/guild_assets.dart';
import 'api/guild_api_client.dart';
import 'api/journey_dto.dart';
import 'models.dart';
import 'quest_repository.dart';

/// Talks to the backend for the endpoints that exist and delegates the rest
/// to [fallback] (the mock) until the backend implements them.
///
/// Backed by the API:
/// - `GET /api/map/journeys/{journeyId}` → [fetchJourney]
class ApiQuestRepository implements QuestRepository {
  ApiQuestRepository({required this.fallback, GuildApiClient? client})
    : _client = client ?? GuildApiClient();

  final QuestRepository fallback;
  final GuildApiClient _client;

  @override
  Future<Journey> fetchJourney(String journeyId) async {
    final json = await _client.getJson(
      '/api/map/journeys/${Uri.encodeComponent(journeyId)}',
    );
    return journeyFromDto(JourneyDetailsDto.fromJson(json));
  }

  @override
  Future<GuildHallData> fetchGuildHall() => fallback.fetchGuildHall();

  @override
  Future<GuildHallData> swearOath(String questId) =>
      fallback.swearOath(questId);

  @override
  Future<GuildHallData> abandonOath(String questId) =>
      fallback.abandonOath(questId);

  @override
  Future<GuildHallData> setTrialDone(
    String questId,
    String trialId, {
    required bool done,
  }) => fallback.setTrialDone(questId, trialId, done: done);

  @override
  Future<GuildHallData> claimBounty(String questId) =>
      fallback.claimBounty(questId);
}

Journey journeyFromDto(JourneyDetailsDto dto) {
  final journeyId = '${dto.id}';
  return Journey(
    id: journeyId,
    name: dto.title,
    emblemAsset: _emblemFor(dto.tileType),
    quote: '',
    bountyXp: 0,
    quests: [
      for (final q in [...dto.activeQuests, ...dto.completedQuests])
        _questFromDto(q, journeyId),
    ],
  );
}

Quest _questFromDto(JourneyQuestDto dto, String journeyId) => Quest(
  id: '${dto.id}',
  journeyId: journeyId,
  title: dto.title,
  flavor: _flavorFor(dto),
  description: '',
  iconAsset: _iconFor(dto.category),
  xp: 0,
  peril: Peril.minor,
  status: _statusFor(dto.status),
  trials: const [],
  startedAt: dto.startedAt,
  completedAt: dto.completedAt,
  durationMinutes: dto.durationMinutes,
);

QuestStatus _statusFor(String status) => switch (status.toUpperCase()) {
  'ACTIVE' => QuestStatus.sworn,
  'COMPLETED' => QuestStatus.fulfilled,
  'LOCKED' => QuestStatus.sealed,
  _ => QuestStatus.open,
};

String _emblemFor(String tileType) => switch (tileType.toUpperCase()) {
  'LIBRARY' => GuildAssets.emblemScholarTower,
  'GYM' || 'TRAINING' || 'BARRACKS' => GuildAssets.emblemIronBody,
  _ => GuildAssets.crestSword,
};

String _iconFor(String category) => switch (category.toUpperCase()) {
  'LEARNING' => GuildAssets.questScroll,
  'FITNESS' || 'SPORT' => GuildAssets.questBoot,
  'HEALTH' => GuildAssets.questPotion,
  _ => GuildAssets.questSword,
};

String _flavorFor(JourneyQuestDto dto) {
  final category = dto.category.isEmpty
      ? ''
      : '${dto.category[0].toUpperCase()}${dto.category.substring(1).toLowerCase()}';
  final minutes = dto.durationMinutes;
  if (minutes == null) return category;
  return category.isEmpty
      ? 'Done in $minutes min'
      : '$category · done in $minutes min';
}
