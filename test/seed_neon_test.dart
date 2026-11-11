import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:verso/neon_db.dart';
import 'package:verso/state.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  test('Seed all default users and pieces into Neon Postgres', () async {
    final state = AppState(enableDiskPersistence: false);
    final db = NeonDb();
    try {
      await db.initSchemaAndLoad(
        defaultUsers: state.users,
        defaultPieces: state.allPieces,
      );
      final users = await db.fetchUsers();
      final pieces = await db.fetchPieces();
      // ignore: avoid_print
      print('SYNC COMPLETE! users in DB: ${users.length}, pieces in DB: ${pieces.length}');
      expect(users.length, greaterThanOrEqualTo(5));
      expect(pieces.length, greaterThanOrEqualTo(16));
    } finally {
      await db.close();
    }
  });
}
