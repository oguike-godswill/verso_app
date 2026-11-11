import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'storage.dart';

class NeonDb {
  static const connectionUrl =
      'postgresql://neondb_owner:npg_7TXvoqiDPYF0@ep-flat-scene-beteg2xs-pooler.c-9.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

  static const _host = 'ep-flat-scene-beteg2xs-pooler.c-9.us-east-2.aws.neon.tech';
  static const _database = 'neondb';
  static const _user = 'neondb_owner';
  static const _password = 'npg_7TXvoqiDPYF0';
  static const _httpSqlEndpoint = 'https://$_host/sql';

  Connection? _conn;
  bool isConnected = false;
  String? lastError;

  Future<Connection?> _getConnection() async {
    if (kIsWeb) return null; // Web uses Neon HTTPS /sql endpoint
    if (_conn != null && _conn!.isOpen) return _conn;
    try {
      _conn = await Connection.open(
        Endpoint(
          host: _host,
          port: 5432,
          database: _database,
          username: _user,
          password: _password,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(seconds: 6),
          queryTimeout: Duration(seconds: 10),
        ),
      );
      isConnected = true;
      lastError = null;
      return _conn;
    } catch (e) {
      lastError = e.toString();
      isConnected = false;
      return null;
    }
  }

  /// Executes a SQL query via Neon HTTP SQL API first (fast, firewall-proof, works on Web & Mobile)
  /// with automatic retry and native TCP fallback.
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?> params = const []]) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final r = await http
            .post(
              Uri.parse(_httpSqlEndpoint),
              headers: {
                'Neon-Connection-String': connectionUrl,
                'Content-Type': 'text/plain',
              },
              body: jsonEncode({
                'query': sql,
                'params': params,
              }),
            )
            .timeout(const Duration(seconds: 14));
        if (r.statusCode >= 200 && r.statusCode < 300) {
          isConnected = true;
          lastError = null;
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          final rows = (body['rows'] as List?) ?? const [];
          return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          lastError = 'HTTP ${r.statusCode}: ${r.body}';
        }
      } catch (e) {
        lastError = e.toString();
      }
      if (attempt == 1) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    // Native TCP fallback if HTTP fails and not on Web
    if (!kIsWeb) {
      try {
        final conn = await _getConnection();
        if (conn != null) {
          final res = await conn.execute(
            Sql(sql),
            parameters: params,
          );
          isConnected = true;
          lastError = null;
          return res.map((row) => row.toColumnMap()).toList();
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    isConnected = false;
    throw Exception(lastError ?? 'Failed to reach Neon PostgreSQL');
  }

  /// Creates the schema on Neon Postgres if not exists and seeds initial data if empty.
  Future<void> initSchemaAndLoad({
    required Map<String, VersoUser> defaultUsers,
    required List<Piece> defaultPieces,
  }) async {
    await query('''
      CREATE TABLE IF NOT EXISTS verso_users (
        email TEXT PRIMARY KEY,
        data JSONB NOT NULL,
        updated_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    await query('''
      CREATE TABLE IF NOT EXISTS verso_pieces (
        id TEXT PRIMARY KEY,
        owner_email TEXT NOT NULL,
        published BOOLEAN NOT NULL DEFAULT FALSE,
        data JSONB NOT NULL,
        updated_at TIMESTAMPTZ DEFAULT NOW()
      )
    ''');

    final existingUsers = await fetchUsers();
    final existingEmails = {for (final u in existingUsers) u.email};
    for (final u in defaultUsers.values) {
      if (!existingEmails.contains(u.email)) {
        await upsertUser(u);
      }
    }

    final existingPieces = await fetchPieces();
    final existingIds = {for (final p in existingPieces) p.id};
    for (final p in defaultPieces) {
      if (!existingIds.contains(p.id)) {
        await upsertPiece(p);
      }
    }
  }

  Future<List<VersoUser>> fetchUsers() async {
    final rows = await query('SELECT email, data FROM verso_users ORDER BY updated_at ASC');
    return rows.map((r) {
      final raw = r['data'];
      final emailCol = r['email'] as String? ?? '';
      final map = raw is String ? jsonDecode(raw) as Map<String, dynamic> : Map<String, dynamic>.from(raw as Map);
      return VersoUser.fromJson(map, emailFallback: emailCol);
    }).where((u) => u.email.isNotEmpty).toList();
  }

  Future<List<Piece>> fetchPieces() async {
    final rows = await query('SELECT id, owner_email, published, data FROM verso_pieces ORDER BY updated_at DESC');
    return rows.map((r) {
      final raw = r['data'];
      final idCol = r['id']?.toString() ?? '';
      final ownerCol = r['owner_email']?.toString() ?? '';
      final map = raw is String ? jsonDecode(raw) as Map<String, dynamic> : Map<String, dynamic>.from(raw as Map);
      if (!map.containsKey('id') && idCol.isNotEmpty) map['id'] = idCol;
      if (!map.containsKey('ownerEmail') && ownerCol.isNotEmpty) map['ownerEmail'] = ownerCol;
      return Piece.fromJson(map);
    }).toList();
  }

  Future<void> upsertUser(VersoUser user) async {
    final payload = jsonEncode(user.toJson());
    await query(
      '''
      INSERT INTO verso_users (email, data, updated_at)
      VALUES (\$1, \$2::jsonb, NOW())
      ON CONFLICT (email) DO UPDATE
      SET data = EXCLUDED.data, updated_at = NOW()
      ''',
      [user.email, payload],
    );
  }

  Future<void> upsertPiece(Piece piece) async {
    final payload = jsonEncode(piece.toJson());
    await query(
      '''
      INSERT INTO verso_pieces (id, owner_email, published, data, updated_at)
      VALUES (\$1, \$2, \$3, \$4::jsonb, NOW())
      ON CONFLICT (id) DO UPDATE
      SET owner_email = EXCLUDED.owner_email,
          published = EXCLUDED.published,
          data = EXCLUDED.data,
          updated_at = NOW()
      ''',
      [piece.id, piece.ownerEmail, piece.published, payload],
    );
  }

  Future<void> deletePiece(String id) async {
    await query('DELETE FROM verso_pieces WHERE id = \$1', [id]);
  }

  Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }
}
