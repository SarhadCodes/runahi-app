DateTime parseSupabaseTime(dynamic value) {
  if (value is DateTime) return value.toUtc();
  final raw = '$value'.trim();
  if (raw.isEmpty || raw == 'null') {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  final normalized = raw
      .replaceFirst(' ', 'T')
      .replaceFirst(RegExp(r'\+00$'), 'Z')
      .replaceFirst(RegExp(r'\+00:00$'), 'Z');
  return DateTime.tryParse(raw)?.toUtc() ??
      DateTime.tryParse(normalized)?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
