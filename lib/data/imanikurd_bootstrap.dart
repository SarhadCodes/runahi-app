import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:imanikurd/imanikurd.dart' as iman;

/// Flutter web decodes JSON numbers as [double]. Imani Kurd casts them to [int].
Object? coerceJsonInts(Object? key, Object? value) {
  if (value is double && value == value.roundToDouble() && value.abs() <= 0x7FFFFFFF) {
    return value.toInt();
  }
  return value;
}

dynamic decodeImaniJson(String raw) => jsonDecode(raw, reviver: coerceJsonInts);

/// Load Imani Kurd JSON from package assets, then the unpkg CDN.
void configureImaniKurd() {
  iman.setDataLoader(_loadImaniFile);
}

Future<dynamic> _loadImaniFile(String filename) async {
  final paths = [
    'packages/imanikurd/assets/data/$filename',
    'assets/data/$filename',
  ];
  for (final path in paths) {
    try {
      final raw = await rootBundle.loadString(path);
      return decodeImaniJson(raw);
    } catch (_) {}
  }

  final response = await Dio().get<String>(
    'https://unpkg.com/imanikurd@1.1.1/data/$filename',
    options: Options(responseType: ResponseType.plain),
  );
  final body = response.data;
  if (response.statusCode != 200 || body == null || body.isEmpty) {
    throw StateError('imanikurd: failed to load $filename');
  }
  return decodeImaniJson(body);
}
