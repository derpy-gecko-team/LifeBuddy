import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifebuddy/buddy/data/buddy_repository.dart';
import 'package:lifebuddy/buddy/data/mock_buddy_repository.dart';
import 'package:lifebuddy/buddy/data/models.dart';
import 'package:lifebuddy/buddy/state/buddy_controller.dart';

/// Answers only when the test says so, or not at all.
class _HeldRepository implements BuddyRepository {
  final asked = <String>[];
  Completer<BuddyReply>? _pending;

  @override
  Future<BuddyReply> interact(String userText) {
    asked.add(userText);
    return (_pending = Completer<BuddyReply>()).future;
  }

  void answer(String message) => _pending!.complete(BuddyReply(message: message));
  void fail() => _pending!.completeError(BuddyException('The raven got lost.'));
}

void main() {
  test('the Buddy answers what the hero sends', () async {
    final controller = BuddyController(MockBuddyRepository(latency: Duration.zero));

    await controller.send('  I want to get fit  ');

    expect(controller.messages.map((m) => m.author), [ChatAuthor.hero, ChatAuthor.buddy]);
    expect(controller.messages.first.text, 'I want to get fit');
    expect(controller.messages.first.status, DeliveryStatus.sent);
    expect(controller.latestFromBuddy!.updatedQuests.single.title, 'Get fit');
    expect(controller.replying, isFalse);
  });

  test('nothing can be sent while the Buddy is still answering, nor an empty line', () async {
    final repository = _HeldRepository();
    final controller = BuddyController(repository);

    await controller.send('   ');
    expect(controller.messages, isEmpty);

    final first = controller.send('one');
    expect(controller.replying, isTrue);
    expect(controller.canSend('two'), isFalse);
    await controller.send('two');
    expect(repository.asked, ['one']);

    repository.answer('Noted.');
    await first;
    expect(controller.canSend('two'), isTrue);
    expect(controller.latestFromBuddy!.text, 'Noted.');
  });

  test('a message that does not get through can be sent again', () async {
    final repository = _HeldRepository();
    final controller = BuddyController(repository);

    final lost = controller.send('hello?');
    repository.fail();
    await lost;

    final undelivered = controller.undelivered!;
    expect(undelivered.text, 'hello?');
    expect(controller.latestFromBuddy, isNull);
    expect(controller.replying, isFalse);

    final again = controller.retry(undelivered.id);
    repository.answer('There you are.');
    await again;

    expect(repository.asked, ['hello?', 'hello?']);
    expect(controller.undelivered, isNull);
    expect(controller.messages.map((m) => m.text), ['hello?', 'There you are.']);
  });

  test('the backend answer is read as it is sent', () {
    final reply = BuddyReply.fromJson({
      'guideMessage': 'Done and dusted.',
      'updatedQuests': [
        {'id': 7, 'title': 'Go to the dentist', 'status': 'IN_PROGRESS'},
      ],
      'newMapTile': {'tileId': 3, 'tileType': 'FOREST', 'q': 1, 'r': -1, 'rotation': 2},
    });

    expect(reply.message, 'Done and dusted.');
    expect(reply.updatedQuests.single.id, '7');
    expect(reply.updatedQuests.single.statusLabel, 'in progress');
    expect(reply.newMapTile!.typeLabel, 'forest');

    final plain = BuddyReply.fromJson({'guideMessage': 'Hm.', 'updatedQuests': [], 'newMapTile': null});
    expect(plain.updatedQuests, isEmpty);
    expect(plain.newMapTile, isNull);
  });
}
