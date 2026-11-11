import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'soundscape.dart';
export 'soundscape.dart';

enum Category { poems, journals, letters }

enum Audience { exhibit, followers, onlyMe }

class DriftingBottle {
  final String id;
  final String text;
  final String location;
  final String author;
  final DateTime castAt;
  int uncorkCount;

  DriftingBottle({
    required this.id,
    required this.text,
    required this.location,
    this.author = 'Anonymous',
    DateTime? castAt,
    this.uncorkCount = 0,
  }) : castAt = castAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'location': location,
        'author': author,
        'castAt': castAt.toIso8601String(),
        'uncorkCount': uncorkCount,
      };

  factory DriftingBottle.fromJson(Map<String, dynamic> j) => DriftingBottle(
        id: (j['id'] ?? '').toString(),
        text: j['text']?.toString() ?? '',
        location: j['location']?.toString() ?? 'North Pier',
        author: j['author']?.toString() ?? 'Anonymous',
        castAt: DateTime.tryParse(j['castAt']?.toString() ?? '') ?? DateTime.now(),
        uncorkCount: (j['uncorkCount'] is num) ? (j['uncorkCount'] as num).toInt() : 0,
      );
}

class NoteReply {
  final String fromHandle;
  final String text;
  final DateTime createdAt;

  NoteReply({
    required this.fromHandle,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'fromHandle': fromHandle,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteReply.fromJson(Map<String, dynamic> j) => NoteReply(
        fromHandle: j['fromHandle'] as String? ?? '@reader',
        text: j['text'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class HeldLine {
  final String line;
  final String pieceId;
  final String pieceTitle;
  final String author;
  final int cover;

  HeldLine({
    required this.line,
    required this.pieceId,
    required this.pieceTitle,
    required this.author,
    required this.cover,
  });

  Map<String, dynamic> toJson() => {
        'line': line,
        'pieceId': pieceId,
        'pieceTitle': pieceTitle,
        'author': author,
        'cover': cover,
      };

  factory HeldLine.fromJson(Map<String, dynamic> j) => HeldLine(
        line: j['line'] as String? ?? '',
        pieceId: j['pieceId'] as String? ?? '',
        pieceTitle: j['pieceTitle'] as String? ?? '',
        author: j['author'] as String? ?? '@ila',
        cover: j['cover'] as int? ?? 0,
      );
}

class Piece {
  final String id;
  String title;
  String body;
  String author;
  String ownerEmail;
  int cover;
  int likes;
  final Set<String> likedBy;
  final Set<String> savedBy;
  bool published;
  Category category;
  DateTime date;
  Audience audience;
  bool allowNotes;
  bool allowHold;
  PaperStock paperStock;
  final List<String> extraPages; // Multi-page chapbook support
  final List<NoteReply> notes;

  Piece({
    required this.id,
    required this.title,
    required this.body,
    this.author = '@ila',
    this.ownerEmail = 'ila@verso.app',
    this.cover = 0,
    this.likes = 0,
    Set<String>? likedBy,
    Set<String>? savedBy,
    this.published = false,
    this.category = Category.poems,
    DateTime? date,
    this.audience = Audience.exhibit,
    this.allowNotes = true,
    this.allowHold = true,
    this.paperStock = PaperStock.warmCream,
    List<String>? extraPages,
    List<NoteReply>? notes,
  })  : likedBy = likedBy ?? <String>{},
        savedBy = savedBy ?? <String>{},
        date = date ?? DateTime.now(),
        extraPages = extraPages ?? <String>[],
        notes = notes ?? <NoteReply>[];

  List<String> get allPages => [body, ...extraPages.where((p) => p.trim().isNotEmpty)];
  bool get isChapbook => extraPages.isNotEmpty;
  int get pageCount => 1 + extraPages.length;

  List<String> get lines => body.split('\n').where((l) => l.trim().isNotEmpty).toList();
  int get words {
    final full = [body, ...extraPages].join(' ').trim();
    return full.isEmpty ? 0 : full.split(RegExp(r'\s+')).length;
  }

  String get firstLine => lines.isEmpty ? (title.isEmpty ? 'Untitled pages' : title) : lines.first;

  bool isLikedBy(String email) => likedBy.contains(email);
  bool isSavedBy(String email) => savedBy.contains(email);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'author': author,
        'ownerEmail': ownerEmail,
        'cover': cover,
        'likes': likes,
        'likedBy': likedBy.toList(),
        'savedBy': savedBy.toList(),
        'published': published,
        'category': category.name,
        'date': date.toIso8601String(),
        'audience': audience.name,
        'allowNotes': allowNotes,
        'allowHold': allowHold,
        'paperStock': paperStock.name,
        'extraPages': extraPages,
        'notes': notes.map((n) => n.toJson()).toList(),
      };

  static bool _asBool(Object? v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    if (v is num) return v != 0;
    return fallback;
  }

  static int _asInt(Object? v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory Piece.fromJson(Map<String, dynamic> j) => Piece(
        id: (j['id'] ?? '').toString(),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        author: j['author']?.toString() ?? '@you',
        ownerEmail: j['ownerEmail']?.toString() ?? '',
        cover: _asInt(j['cover'], 0),
        likes: _asInt(j['likes'], 0),
        likedBy: ((j['likedBy'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        savedBy: ((j['savedBy'] as List?) ?? const []).map((e) => e.toString()).toSet(),
        published: _asBool(j['published'], false),
        category: Category.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => Category.poems,
        ),
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        audience: Audience.values.firstWhere(
          (a) => a.name == j['audience'],
          orElse: () => Audience.exhibit,
        ),
        allowNotes: _asBool(j['allowNotes'], true),
        allowHold: _asBool(j['allowHold'], true),
        paperStock: PaperStock.values.firstWhere(
          (s) => s.name == j['paperStock'],
          orElse: () => PaperStock.warmCream,
        ),
        extraPages: ((j['extraPages'] as List?) ?? const []).map((e) => e.toString()).toList(),
        notes: ((j['notes'] as List?) ?? const [])
            .map((e) => NoteReply.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class VersoUser {
  final String email;
  String passwordHash;
  String name;
  String handle;
  String bio;
  int avatarCover;
  final Set<String> following;
  final List<HeldLine> heldLines;

  VersoUser({
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.handle,
    this.bio = 'Leaving quiet pages by the water.',
    this.avatarCover = 0,
    Set<String>? following,
    List<HeldLine>? heldLines,
  })  : following = following ?? <String>{},
        heldLines = heldLines ?? <HeldLine>[];

  Map<String, dynamic> toJson() => {
        'email': email,
        'passwordHash': passwordHash,
        'name': name,
        'handle': handle,
        'bio': bio,
        'avatarCover': avatarCover,
        'following': following.toList(),
        'heldLines': heldLines.map((h) => h.toJson()).toList(),
      };

  factory VersoUser.fromJson(Map<String, dynamic> j, {String? emailFallback}) {
    final emailStr = (j['email'] as String?) ?? emailFallback ?? '';
    return VersoUser(
      email: emailStr,
      passwordHash: j['passwordHash'] as String? ?? '',
      name: j['name'] as String? ?? 'Writer',
      handle: j['handle'] as String? ?? '@writer',
      bio: j['bio'] as String? ?? 'Leaving quiet pages by the water.',
      avatarCover: j['avatarCover'] as int? ?? 0,
      following: ((j['following'] as List?) ?? const []).map((e) => e.toString()).toSet(),
      heldLines: ((j['heldLines'] as List?) ?? const [])
          .map((e) => HeldLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Lightweight local JSON file storage so user accounts and pieces persist offline too.
class LocalStore {
  static File? _resolveFile() {
    if (kIsWeb) return null;
    try {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path;
      return File('$home${Platform.pathSeparator}.verso_store_v2.json');
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? loadSync() {
    final file = _resolveFile();
    if (file == null || !file.existsSync()) return null;
    try {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static void saveSync(Map<String, dynamic> data) {
    final file = _resolveFile();
    if (file == null) return;
    try {
      file.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }
}
