import 'package:flutter_test/flutter_test.dart';
import 'package:rounahi/core/utils/supabase_time.dart';

void main() {
  test('parses PostgREST and Postgres timestamptz values', () {
    expect(
      parseSupabaseTime('2026-09-20 13:40:13.564464+00').isUtc,
      isTrue,
    );
    expect(
      parseSupabaseTime('2026-09-20 13:40:13.564464+00').year,
      2026,
    );
    expect(
      parseSupabaseTime('2026-09-20T13:40:13.564464+00:00').hour,
      13,
    );
    expect(
      parseSupabaseTime('2026-09-20T13:40:13.564464Z').minute,
      40,
    );
  });
}
