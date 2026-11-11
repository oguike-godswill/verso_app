import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  test('compare Neon HTTP SQL with and without channel_binding', () async {
    const host = 'ep-flat-scene-beteg2xs-pooler.c-9.us-east-2.aws.neon.tech';
    const urlWithChannel =
        'postgresql://neondb_owner:npg_7TXvoqiDPYF0@$host/neondb?sslmode=require&channel_binding=require';
    final r1 = await http.post(
      Uri.parse('https://$host/sql'),
      headers: {
        'Neon-Connection-String': urlWithChannel,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': 'SELECT email FROM verso_users',
        'params': [],
      }),
    );
    // ignore: avoid_print
    print('WITH CHANNEL_BINDING STATUS: ${r1.statusCode} BODY: ${r1.body}');
  });
}
