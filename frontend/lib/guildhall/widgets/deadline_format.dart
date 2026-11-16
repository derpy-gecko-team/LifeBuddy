const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String deadlineLabel(DateTime deadline, DateTime now) {
  final days = _day(deadline).difference(_day(now)).inDays;
  if (days < 0 || deadline.isBefore(now)) return 'Overdue';
  if (days == 0) return deadline.hour < 20 ? 'By dusk' : 'By midnight';
  if (days == 1) return 'Tomorrow';
  if (days < 7) return 'In $days days';
  return '${deadline.day} ${_months[deadline.month - 1]}';
}

String deadlineDate(DateTime deadline) =>
    '${deadline.day} ${_months[deadline.month - 1]}';

String deadlineRelative(DateTime deadline, DateTime now) {
  final days = _day(deadline).difference(_day(now)).inDays;
  if (days < 0) return '${-days} days ago';
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}
