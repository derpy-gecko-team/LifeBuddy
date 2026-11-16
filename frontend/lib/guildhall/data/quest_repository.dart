import 'models.dart';

abstract interface class QuestRepository {
  Future<GuildHallData> fetchGuildHall();

  Future<GuildHallData> swearOath(String questId);

  Future<GuildHallData> abandonOath(String questId);

  Future<GuildHallData> setTrialDone(
    String questId,
    String trialId, {
    required bool done,
  });

  Future<GuildHallData> claimBounty(String questId);
}

class QuestActionException implements Exception {
  QuestActionException(this.message);
  final String message;

  @override
  String toString() => message;
}
