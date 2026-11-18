import 'package:flutter/foundation.dart';

/// A way for the rest of the app to reach into the Guild Hall: to say the
/// quests have changed behind its back, or to ask it to show one of them.
///
/// The Buddy uses it: when a conversation posts or fulfils a quest, the
/// board is told to look again, and a tap on the quest in the Buddy's answer
/// opens that quest's notice.
class GuildHallRemote extends ChangeNotifier {
  String? _questToOpen;

  /// The quests changed somewhere else; fetch them again.
  void refresh() => notifyListeners();

  /// Fetch the quests again, then open this one.
  void openQuest(String questId) {
    _questToOpen = questId;
    notifyListeners();
  }

  /// The quest asked for since the last call, if any. Asking clears it.
  String? takeQuestToOpen() {
    final id = _questToOpen;
    _questToOpen = null;
    return id;
  }
}
