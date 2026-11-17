import 'package:flutter/foundation.dart';

enum ChatAuthor { hero, buddy }

enum DeliveryStatus { sending, sent, failed }

/// A quest the Buddy touched while answering (`QuestSummary` on the backend).
@immutable
class QuestUpdate {
  const QuestUpdate({required this.id, required this.title, required this.status, this.xp});

  factory QuestUpdate.fromJson(Map<String, dynamic> json) => QuestUpdate(
    id: '${json['id']}',
    title: json['title'] as String,
    status: json['status'] as String? ?? '',
    xp: (json['xp'] as num?)?.toInt(),
  );

  final String id;
  final String title;
  final String status;

  /// What the quest is worth, when the answer says. (The server's
  /// `QuestSummary` does not carry it yet.)
  final int? xp;

  /// Whether the Buddy is reporting this quest as finished.
  bool get fulfilled => const {'COMPLETED', 'FULFILLED', 'DONE'}.contains(status.toUpperCase());

  /// How the quest is named in the Buddy's answer.
  String get linkLabel => fulfilled ? 'Fulfilled: $title' : 'On the board: $title';

  /// "IN_PROGRESS" -> "in progress".
  String get statusLabel => status.replaceAll('_', ' ').toLowerCase();
}

/// A tile the answer added to the map (`MapTileSummary` on the backend).
@immutable
class MapTileUpdate {
  const MapTileUpdate({
    required this.tileId,
    required this.tileType,
    required this.q,
    required this.r,
    this.rotation = 0,
  });

  factory MapTileUpdate.fromJson(Map<String, dynamic> json) => MapTileUpdate(
    tileId: '${json['tileId']}',
    tileType: json['tileType'] as String,
    q: json['q'] as int,
    r: json['r'] as int,
    rotation: json['rotation'] as int? ?? 0,
  );

  final String tileId;
  final String tileType;
  final int q;
  final int r;
  final int rotation;

  String get typeLabel => tileType.replaceAll('_', ' ').toLowerCase();
}

/// What `POST /api/guide/interact` answers with (`InteractionResponse`).
@immutable
class BuddyReply {
  const BuddyReply({required this.message, this.updatedQuests = const [], this.newMapTile});

  factory BuddyReply.fromJson(Map<String, dynamic> json) => BuddyReply(
    message: json['guideMessage'] as String,
    updatedQuests: [
      for (final quest in json['updatedQuests'] as List<dynamic>? ?? const [])
        QuestUpdate.fromJson(quest as Map<String, dynamic>),
    ],
    newMapTile: json['newMapTile'] == null ? null : MapTileUpdate.fromJson(json['newMapTile'] as Map<String, dynamic>),
  );

  final String message;
  final List<QuestUpdate> updatedQuests;
  final MapTileUpdate? newMapTile;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.sentAt,
    this.status = DeliveryStatus.sent,
    this.updatedQuests = const [],
    this.newMapTile,
  });

  final String id;
  final ChatAuthor author;
  final String text;
  final DateTime sentAt;

  /// Only ever anything but [DeliveryStatus.sent] for the hero's own messages.
  final DeliveryStatus status;

  final List<QuestUpdate> updatedQuests;
  final MapTileUpdate? newMapTile;

  bool get fromBuddy => author == ChatAuthor.buddy;

  ChatMessage copyWith({DeliveryStatus? status}) => ChatMessage(
    id: id,
    author: author,
    text: text,
    sentAt: sentAt,
    status: status ?? this.status,
    updatedQuests: updatedQuests,
    newMapTile: newMapTile,
  );
}
