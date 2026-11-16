/// How the Buddy hears the hero: speech in, words out.
///
/// The app talks to this, not to a speech engine, so the engine can change
/// (the phone's own recogniser today, a model on the server some day)
/// without the page knowing.
abstract interface class BuddyEars {
  /// Starts listening.
  ///
  /// [onWords] is given everything heard so far, each time that changes.
  /// [onEnded] is called exactly once when listening is over, whether
  /// because [stop] was called, the hero went quiet, or something broke;
  /// by then the last words have been through [onWords].
  ///
  /// [onLoudness], if given, is told how loud the hero is being right now,
  /// from 0 (silence) to 1 (as loud as they have been), many times a second.
  ///
  /// Throws an [EarsException] if listening cannot start at all.
  Future<void> start({
    required void Function(String words) onWords,
    required void Function() onEnded,
    void Function(double loudness)? onLoudness,
  });

  /// Asks for the last words and the end. [start]'s `onEnded` follows.
  Future<void> stop();

  /// Stops and throws away what was heard. `onEnded` is not called.
  Future<void> cancel();
}

class EarsException implements Exception {
  EarsException(this.message);

  /// Said by the Buddy, so written in its voice.
  final String message;

  @override
  String toString() => message;
}
