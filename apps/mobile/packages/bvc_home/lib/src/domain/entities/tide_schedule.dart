class TideSchedule {
  TideSchedule({
    required this.id,
    required this.date,
    required this.lowTime1,
    required this.lowHeight1,
    required this.lowTime2,
    required this.lowHeight2,
    required this.isGolden,
    required this.note,
  });

  final String id;
  final DateTime date;
  final DateTime lowTime1;
  final double lowHeight1;
  final DateTime? lowTime2;
  final double? lowHeight2;
  final bool isGolden;
  final String? note;

  factory TideSchedule.fromJson(Map<String, dynamic> json) {
    DateTime dt(String k) => DateTime.parse(json[k] as String);
    double d(String k) => (json[k] as num).toDouble();

    return TideSchedule(
      id: json['id'] as String,
      date: dt('date'),
      lowTime1: dt('lowTime1'),
      lowHeight1: d('lowHeight1'),
      lowTime2: json['lowTime2'] == null ? null : dt('lowTime2'),
      lowHeight2: json['lowHeight2'] == null ? null : (json['lowHeight2'] as num).toDouble(),
      isGolden: json['isGolden'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
