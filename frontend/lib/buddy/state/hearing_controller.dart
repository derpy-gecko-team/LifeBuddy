import 'package:flutter/foundation.dart';

import '../data/buddy_ears.dart';

enum Hearing {
  /// Not listening.
  idle,

  /// The horn was tapped; waiting for the microphone (and, the first time,
  /// for the hero to allow it).
  waking,

  /// Listening. [HearingController.words] fills in as the hero speaks.
  listening,

  /// The horn was tapped again; waiting for the last words.
  finishing,
}

/// The horn: tap to be heard, tap again to send what was heard.
class HearingController extends ChangeNotifier {
  HearingController(this._ears, {required this.onHeard});

  final BuddyEars _ears;

  /// Given what the hero said, once they are done saying it.
  final void Function(String words) onHeard;

  Hearing _state = Hearing.idle;
  Hearing get state => _state;

  bool get active => _state != Hearing.idle;

  String _words = '';

  /// What has been heard so far in this go.
  String get words => _words;

  final _loudness = ValueNotifier<double>(0);

  /// How loud the hero is being right now, 0 to 1. It changes many times a
  /// second, so it is its own listenable and does not wake [addListener]s.
  ValueListenable<double> get loudness => _loudness;

  String? _trouble;

  /// Why the last attempt to listen came to nothing, in the Buddy's words.
  String? get trouble => _trouble;

  bool _disposed = false;

  Future<void> toggle() => active ? finish() : start();

  Future<void> start() async {
    if (active) return;
    _trouble = null;
    _words = '';
    _set(Hearing.waking);
    try {
      await _ears.start(onWords: _onWords, onEnded: _onEnded, onLoudness: _onLoudness);
      // Unless it was cancelled, or ended, while the microphone woke.
      if (_state == Hearing.waking) _set(Hearing.listening);
    } on EarsException catch (e) {
      _trouble = e.message;
      _set(Hearing.idle);
    }
  }

  /// Done talking: collect the last words, then [onHeard].
  Future<void> finish() async {
    if (_state != Hearing.listening) return;
    _set(Hearing.finishing);
    await _ears.stop();
  }

  /// Never mind: stop and send nothing.
  Future<void> cancel() async {
    if (!active) return;
    _words = '';
    _set(Hearing.idle);
    await _ears.cancel();
  }

  void clearTrouble() {
    if (_trouble == null) return;
    _trouble = null;
    _notify();
  }

  void _onLoudness(double loudness) {
    if (_state == Hearing.listening && !_disposed) _loudness.value = loudness.clamp(0.0, 1.0);
  }

  void _onWords(String words) {
    if (!active || words == _words) return;
    _words = words;
    _notify();
  }

  // Also reached when the hero simply stops talking for a while: what was
  // said is sent, as if the horn had been tapped.
  void _onEnded() {
    if (!active) return;
    final heard = _words.trim();
    _state = Hearing.idle;
    if (!_disposed) _loudness.value = 0;
    // Handed over before anyone is told the listening is over, so that
    // listeners can tell "sent" from "came to nothing".
    if (heard.isNotEmpty && !_disposed) onHeard(heard);
    _notify();
  }

  void _set(Hearing state) {
    _state = state;
    if (state != Hearing.listening && !_disposed) _loudness.value = 0;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (active) _ears.cancel();
    _loudness.dispose();
    super.dispose();
  }
}
