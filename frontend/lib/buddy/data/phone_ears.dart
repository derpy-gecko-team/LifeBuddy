import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'buddy_ears.dart';

/// Listens with the phone's own speech recogniser (Android's speech service,
/// Apple's on iOS). English only for now. Nothing leaves the app's side: the
/// words come back as text and go to the Buddy like typed ones.
class PhoneEars implements BuddyEars {
  PhoneEars({this.locale = 'en_US'});

  final String locale;

  final _speech = SpeechToText();
  bool? _ready;

  void Function()? _onEnded;
  Timer? _giveUp;

  static const _deaf = 'I can’t hear a thing on this device. Write it down for me instead.';
  static const _notAllowed =
      'You have not let me use the microphone. Allow it in the phone’s settings, or write it down for me.';

  // The recogniser reports loudness in its own units, which differ between
  // Android and iOS and between phones. So the scale is learnt as it goes:
  // the quietest and loudest levels heard so far are taken as 0 and 1.
  double _quiet = double.infinity;
  double _loud = double.negativeInfinity;

  double _loudness(double level) {
    if (level < _quiet) _quiet = level;
    if (level > _loud) _loud = level;
    // Until a real range has been heard, do not call a whisper a shout.
    final range = _loud - _quiet;
    if (range < 3) return 0;
    return ((level - _quiet) / range).clamp(0.0, 1.0);
  }

  @override
  Future<void> start({
    required void Function(String words) onWords,
    required void Function() onEnded,
    void Function(double loudness)? onLoudness,
  }) async {
    // The first call is the one that asks for the microphone.
    try {
      _ready ??= await _speech.initialize(onStatus: _onStatus, onError: _onError);
    } catch (_) {
      _ready = null;
      throw EarsException(_deaf);
    }
    if (_ready != true) {
      final allowed = await _speech.hasPermission;
      _ready = null; // ask again next time: the answer may have changed in settings
      throw EarsException(allowed ? _deaf : _notAllowed);
    }

    _onEnded = onEnded;
    try {
      await _speech.listen(
        onResult: (result) => onWords(result.recognizedWords),
        onSoundLevelChange: onLoudness == null ? null : (level) => onLoudness(_loudness(level)),
        listenOptions: SpeechListenOptions(
          localeId: locale,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          // As long as the recogniser allows. The hero ends it with the
          // horn; a long silence ends it too.
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 6),
        ),
      );
    } catch (_) {
      _onEnded = null;
      throw EarsException(_deaf);
    }
  }

  @override
  Future<void> stop() async {
    if (_onEnded == null) return;
    // The last words arrive a moment after stopping, then the "done" status.
    // Should that never come, end anyway.
    _giveUp = Timer(const Duration(seconds: 3), _end);
    await _speech.stop();
  }

  @override
  Future<void> cancel() async {
    _giveUp?.cancel();
    _onEnded = null;
    await _speech.cancel();
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) _end();
  }

  void _onError(SpeechRecognitionError error) => _end();

  void _end() {
    _giveUp?.cancel();
    final ended = _onEnded;
    _onEnded = null;
    ended?.call();
  }
}
