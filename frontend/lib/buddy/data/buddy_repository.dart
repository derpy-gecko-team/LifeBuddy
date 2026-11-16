import 'models.dart';

abstract interface class BuddyRepository {
  /// Longest message the backend accepts (`UserSpeechRequest.userText`).
  static const maxMessageLength = 2000;

  /// Tells the Buddy something and waits for its answer
  /// (`POST /api/guide/interact`).
  Future<BuddyReply> interact(String userText);
}

class BuddyException implements Exception {
  BuddyException(this.message);
  final String message;

  @override
  String toString() => message;
}
