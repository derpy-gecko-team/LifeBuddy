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

  Questline? questlineById(String id) {
    for (final l in _data?.questlines ?? const <Questline>[]) {
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
