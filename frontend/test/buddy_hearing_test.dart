import 'package:flutter_test/flutter_test.dart';
import 'package:lifebuddy/buddy/data/buddy_ears.dart';
import 'package:lifebuddy/buddy/state/hearing_controller.dart';

/// Ears the test speaks into.
class FakeEars implements BuddyEars {
  FakeEars({this.refuses});

  /// If set, listening cannot start, for this reason.
  final String? refuses;

  void Function(String words)? _onWords;
  void Function()? _onEnded;
  bool cancelled = false;

  bool get listening => _onEnded != null;

  @override
  Future<void> start({required void Function(String words) onWords, required void Function() onEnded}) async {
    if (refuses != null) throw EarsException(refuses!);
    _onWords = onWords;
    _onEnded = onEnded;
  }

  void hear(String words) => _onWords!(words);

  /// The recogniser ends on its own, as it does after a long silence.
  void fallSilent() => _end();

  @override
  Future<void> stop() async => _end();

  @override
  Future<void> cancel() async {
    cancelled = true;
    _onEnded = null;
  }

  void _end() {
    final ended = _onEnded;
    _onEnded = null;
    ended?.call();
  }
}

void main() {
  late FakeEars ears;
  late List<String> heard;
  late HearingController hearing;

  setUp(() {
    ears = FakeEars();
    heard = [];
    hearing = HearingController(ears, onHeard: heard.add);
  });

  test('the horn listens on the first tap and sends what it heard on the second', () async {
    await hearing.toggle();
    expect(hearing.state, Hearing.listening);

    ears.hear('I want');
    ears.hear('I want to get fit');
    expect(hearing.words, 'I want to get fit');
    expect(heard, isEmpty);

    await hearing.toggle();
    expect(hearing.state, Hearing.idle);
    expect(heard, ['I want to get fit']);
  });

  test('going quiet sends what was said, without a second tap', () async {
    await hearing.start();
    ears.hear('walk the dog');
    ears.fallSilent();

    expect(hearing.active, isFalse);
    expect(heard, ['walk the dog']);
  });

  test('nothing is sent when nothing was said', () async {
    await hearing.start();
    await hearing.finish();

    expect(hearing.active, isFalse);
    expect(heard, isEmpty);
    expect(hearing.trouble, isNull);
  });

  test('cancelling throws away what was heard', () async {
    await hearing.start();
    ears.hear('never mind');
    await hearing.cancel();

    expect(ears.cancelled, isTrue);
    expect(hearing.active, isFalse);
    expect(hearing.words, isEmpty);
    expect(heard, isEmpty);
  });

  test('ears that cannot listen leave a reason, cleared by the next attempt', () async {
    final deaf = HearingController(FakeEars(refuses: 'No microphone.'), onHeard: heard.add);
    await deaf.start();
    expect(deaf.state, Hearing.idle);
    expect(deaf.trouble, 'No microphone.');

    deaf.clearTrouble();
    expect(deaf.trouble, isNull);
  });

  test('listeners learn of the words before they learn the listening is over', () async {
    final order = <String>[];
    hearing = HearingController(ears, onHeard: (_) => order.add('heard'));
    await hearing.start();
    ears.hear('hello');
    hearing.addListener(() => order.add(hearing.active ? 'active' : 'over'));
    await hearing.finish();

    expect(order, ['active', 'heard', 'over']);
  });
}
