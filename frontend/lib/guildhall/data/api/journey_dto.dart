/// Response of `GET /api/map/journeys/{journeyId}`.
class JourneyDetailsDto {
  const JourneyDetailsDto({
    required this.id,
    required this.title,
    required this.tileType,
    required this.q,
    required this.r,
    required this.status,
    required this.activeQuests,
    required this.completedQuests,
  });

  factory JourneyDetailsDto.fromJson(Map<String, dynamic> json) =>
      JourneyDetailsDto(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        tileType: json['tileType'] as String? ?? '',
        q: (json['q'] as num?)?.toInt() ?? 0,
        r: (json['r'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? '',
        activeQuests: _quests(json['activeQuests']),
        completedQuests: _quests(json['completedQuests']),
      );

  final int id;
  final String title;
  final String tileType;
  final int q;
  final int r;
  final String status;
  final List<JourneyQuestDto> activeQuests;
  final List<JourneyQuestDto> completedQuests;

  static List<JourneyQuestDto> _quests(Object? raw) => [
    for (final item in (raw as List<dynamic>? ?? const []))
      JourneyQuestDto.fromJson(item as Map<String, dynamic>),
  ];
}

class JourneyQuestDto {
  const JourneyQuestDto({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.durationMinutes,
  });

  factory JourneyQuestDto.fromJson(Map<String, dynamic> json) =>
      JourneyQuestDto(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        status: json['status'] as String? ?? '',
        startedAt: _date(json['startedAt']),
        completedAt: _date(json['completedAt']),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      );

  final int id;
  final String title;
  final String category;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? durationMinutes;

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
