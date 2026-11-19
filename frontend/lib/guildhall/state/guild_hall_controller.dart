import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/quest_repository.dart';

enum QuestFilter {
  all('All quests'),
  sworn('Sworn'),
  sealed('Sealed'),
  fulfilled('Fulfilled');

  const QuestFilter(this.label);
  final String label;

  bool matches(Quest q) => switch (this) {
        QuestFilter.all => true,
        QuestFilter.sworn => q.status == QuestStatus.sworn,
        QuestFilter.sealed => q.status == QuestStatus.sealed,
        QuestFilter.fulfilled => q.status == QuestStatus.fulfilled,
      };
}

class GuildHallController extends ChangeNotifier {
  GuildHallController(this._repository, {Future<void> Function()? beforeFirstLoad})
      : _beforeFirstLoad = beforeFirstLoad;

  final QuestRepository _repository;

  Future<void> Function()? _beforeFirstLoad;

  GuildHallData? _data;
  GuildHallData? get data => _data;

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  QuestFilter _filter = QuestFilter.all;
  QuestFilter get filter => _filter;

  bool _busy = false;

  final Set<String> _loadingJourneys = {};
  final Map<String, Object> _journeyErrors = {};

  bool isJourneyLoading(String journeyId) => _loadingJourneys.contains(journeyId);
  Object? journeyError(String journeyId) => _journeyErrors[journeyId];

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final warmUp = _beforeFirstLoad?.call();
      _beforeFirstLoad = null;
      final data = await _repository.fetchGuildHall();
      await warmUp;
      _data = data;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refreshes one journey from the repository and merges it into [data].
  /// On failure, any journey already on the board stays as it was.
  Future<void> loadJourney(String journeyId) async {
    if (!_loadingJourneys.add(journeyId)) return;
    _journeyErrors.remove(journeyId);
    notifyListeners();
    try {
      final fresh = await _repository.fetchJourney(journeyId);
      final data = _data;
      if (data != null) _data = data.copyWith(journeys: _mergeJourney(data.journeys, fresh));
    } catch (e) {
      _journeyErrors[journeyId] = e;
    } finally {
      _loadingJourneys.remove(journeyId);
      notifyListeners();
    }
  }

  static List<Journey> _mergeJourney(List<Journey> journeys, Journey fresh) {
    final index = journeys.indexWhere((j) => j.id == fresh.id);
    if (index < 0) return [...journeys, fresh];
    // Keep board-side decoration (emblem, quote, bounty) the API does not send.
    final merged = journeys[index].copyWith(name: fresh.name, quests: fresh.quests);
    return [...journeys]..[index] = merged;
  }

  void setFilter(QuestFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    notifyListeners();
  }

  int countFor(QuestFilter filter) =>
      _data?.allQuests.where(filter.matches).length ?? 0;

  Quest? questById(String id) {
    for (final q in _data?.allQuests ?? const <Quest>[]) {
      if (q.id == id) return q;
    }
    return null;
  }

  Journey? journeyById(String id) {
    for (final l in _data?.journeys ?? const <Journey>[]) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> swearOath(String questId) =>
      _run(() => _repository.swearOath(questId));

  Future<void> abandonOath(String questId) =>
      _run(() => _repository.abandonOath(questId));

  Future<void> setTrialDone(String questId, String trialId, bool done) =>
      _run(() => _repository.setTrialDone(questId, trialId, done: done));

  Future<void> claimBounty(String questId) =>
      _run(() => _repository.claimBounty(questId));

  Future<void> _run(Future<GuildHallData> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      _data = await action();
      notifyListeners();
    } finally {
      _busy = false;
    }
  }
}
