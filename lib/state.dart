import 'dart:async';
import 'package:flutter/material.dart';
import 'neon_db.dart';
import 'storage.dart';
export 'storage.dart';

const months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

const dailyPrompts = [
  'What did the water keep after you left?',
  'Write four lines to someone who moved away.',
  'Describe the sound of an empty room at 6 a.m.',
  'Name three small things that stayed quiet today.',
  'Begin with a color you only see in winter.',
];

class AppState extends ChangeNotifier {
  int tab = 0;
  final bool enableDiskPersistence;
  final NeonDb neon = NeonDb();
  bool? _neonSynced = false;
  bool? _neonSyncing = false;

  bool get neonSynced => _neonSynced == true;
  set neonSynced(bool v) => _neonSynced = v;

  bool get neonSyncing => _neonSyncing == true;
  set neonSyncing(bool v) => _neonSyncing = v;

  bool midnightLamp = false;
  void toggleMidnightLamp() {
    midnightLamp = !midnightLamp;
    notifyListeners();
  }

  int promptIndex = 0;
  String get currentPrompt => dailyPrompts[promptIndex % dailyPrompts.length];
  void nextPrompt() {
    promptIndex = (promptIndex + 1) % dailyPrompts.length;
    notifyListeners();
  }

  final Map<String, VersoUser> users = {};
  final List<Piece> allPieces = [];
  final List<DriftingBottle> bottles = [];
  VersoUser? currentUser;

  AppState({this.enableDiskPersistence = true}) {
    _seedDefaults();
    if (enableDiskPersistence) {
      _loadFromDisk();
      unawaited(syncWithNeon());
    }
  }

  /// Connects to Neon PostgreSQL, ensures tables exist, seeds defaults if empty,
  /// and merges remote users & pieces into the live app state.
  Future<void> syncWithNeon() async {
    if (neonSyncing) return;
    neonSyncing = true;
    notifyListeners();
    try {
      await neon.initSchemaAndLoad(defaultUsers: users, defaultPieces: allPieces);
      final remoteUsers = await neon.fetchUsers();
      final remotePieces = await neon.fetchPieces();

      if (remoteUsers.isNotEmpty) {
        final activeEmail = currentUser?.email;
        for (final u in remoteUsers) {
          users[u.email] = u;
        }
        if (activeEmail != null && users.containsKey(activeEmail)) {
          currentUser = users[activeEmail];
        }
      }
      if (remotePieces.isNotEmpty) {
        final byId = {for (final p in allPieces) p.id: p};
        for (final rp in remotePieces) {
          byId[rp.id] = rp;
        }
        allPieces
          ..clear()
          ..addAll(byId.values);
      }
      neonSynced = true;
      _persistLocalOnly();
    } catch (_) {
      neonSynced = false;
    } finally {
      neonSyncing = false;
      notifyListeners();
    }
  }

  void _seedDefaults() {
    users['ila@verso.app'] = VersoUser(
      email: 'ila@verso.app',
      passwordHash: _hash('quietlake'),
      name: 'Ila',
      handle: '@ila',
      bio: 'Poems and small boats on the north shore.',
      avatarCover: 0,
      following: {'@noor', '@theo'},
      heldLines: [
        HeldLine(
          line: 'Small boats learn quiet',
          pieceId: 'e2',
          pieceTitle: 'Small boats learn quiet.',
          author: '@noor',
          cover: 1,
        ),
      ],
    );
    users['noor@verso.app'] = VersoUser(
      email: 'noor@verso.app',
      passwordHash: _hash('quietlake'),
      name: 'Noor',
      handle: '@noor',
      bio: 'Collecting letters that were never mailed.',
      avatarCover: 1,
    );
    users['theo@verso.app'] = VersoUser(
      email: 'theo@verso.app',
      passwordHash: _hash('quietlake'),
      name: 'Theo',
      handle: '@theo',
      bio: 'Cartographer of small harbors and winter tides.',
      avatarCover: 4,
    );
    users['mara@verso.app'] = VersoUser(
      email: 'mara@verso.app',
      passwordHash: _hash('quietlake'),
      name: 'Mara',
      handle: '@mara',
      bio: 'Notes from a lighthouse kitchen.',
      avatarCover: 3,
    );
    users['soren@verso.app'] = VersoUser(
      email: 'soren@verso.app',
      passwordHash: _hash('quietlake'),
      name: 'Soren',
      handle: '@soren',
      bio: 'Mountain passes and late trains.',
      avatarCover: 5,
    );

    allPieces.addAll([
      Piece(
        id: 'e1',
        title: 'The Lake',
        author: '@ila',
        ownerEmail: 'ila@verso.app',
        cover: 0,
        likes: 128,
        published: true,
        date: DateTime(2026, 11, 6),
        body: 'The lake kept my shape\nlong after I left it.\nA small boat out there\nis still learning to be quiet.\n\n'
            'I wrote your name on the water\nand let the wind argue.',
        notes: [
          NoteReply(fromHandle: '@noor', text: '“still learning to be quiet” stayed with me all afternoon.'),
        ],
      ),
      Piece(
        id: 'e2',
        title: 'Small boats learn quiet.',
        author: '@noor',
        ownerEmail: 'noor@verso.app',
        cover: 1,
        likes: 212,
        published: true,
        date: DateTime(2026, 11, 4),
        body: 'Small boats learn quiet\nthe way children learn names,\nby being called\nuntil they answer.',
      ),
      Piece(
        id: 'e3',
        title: 'Your name, written on water.',
        author: '@theo',
        ownerEmail: 'theo@verso.app',
        cover: 2,
        likes: 86,
        published: true,
        date: DateTime(2026, 11, 2),
        body: 'Your name, written on water,\nheld for a breath,\nthen became the lake.',
      ),
      Piece(
        id: 'e4',
        title: 'Salt, then silence.',
        author: '@mara',
        ownerEmail: 'mara@verso.app',
        cover: 3,
        likes: 54,
        published: true,
        date: DateTime(2026, 10, 29),
        body: 'Salt, then silence.\nThe sea forgets nothing\nbut forgives\neverything.',
      ),
      Piece(
        id: 'e5',
        title: 'Tuesday, fog.',
        author: '@ila',
        ownerEmail: 'ila@verso.app',
        cover: 2,
        likes: 41,
        published: true,
        category: Category.journals,
        date: DateTime(2026, 11, 3),
        body: 'Fog all morning.\nI made tea twice and drank neither.\nThe window held the whole harbor in grey.',
      ),
      Piece(
        id: 'e6',
        title: 'Dear M.',
        author: '@noor',
        ownerEmail: 'noor@verso.app',
        cover: 1,
        likes: 97,
        published: true,
        category: Category.letters,
        date: DateTime(2026, 11, 1),
        body: 'Dear M.,\nThe boat is still where you left it.\nI row it out sometimes, just to bring it back.',
      ),
      Piece(
        id: 'e7',
        title: 'Keeper’s Log, Midnight',
        author: '@mara',
        ownerEmail: 'mara@verso.app',
        cover: 4,
        likes: 143,
        published: true,
        paperStock: PaperStock.midnightHarbor,
        date: DateTime(2026, 11, 5),
        body: 'The lantern turns once every twelve seconds.\nBetween flashes, the sea belongs to itself.\n\n'
            'I brewed coffee at two\nand watched a freighter pass without a sound.',
        extraPages: [
          'II.\nAt dawn the gulls sit on the iron rail\nwaiting for the lamp to cool.',
        ],
      ),
      Piece(
        id: 'e8',
        title: 'Above the snowline',
        author: '@soren',
        ownerEmail: 'soren@verso.app',
        cover: 5,
        likes: 78,
        published: true,
        date: DateTime(2026, 10, 31),
        body: 'Above the snowline\neven the pine trees stop explaining themselves.\nOnly the wind keeps a ledger.',
      ),
      Piece(
        id: 'e9',
        title: 'October 28 · Low tide',
        author: '@theo',
        ownerEmail: 'theo@verso.app',
        cover: 7,
        likes: 65,
        published: true,
        category: Category.journals,
        paperStock: PaperStock.fadedParchment,
        date: DateTime(2026, 10, 28),
        body: 'Walked the breakwater with my coat unbuttoned.\nFound half a blue teacup wedged between two stones.\nLeft it for the next tide to finish.',
      ),
      Piece(
        id: 'e10',
        title: 'November 4 · Train to Bergen',
        author: '@soren',
        ownerEmail: 'soren@verso.app',
        cover: 5,
        likes: 112,
        published: true,
        category: Category.journals,
        date: DateTime(2026, 11, 4),
        body: 'Four hours of tunnels and sudden fjords.\nThe woman across from me peeled an orange in one unbroken spiral\nand fell asleep before eating it.',
      ),
      Piece(
        id: 'e11',
        title: 'To the next tenant of Room 4B',
        author: '@theo',
        ownerEmail: 'theo@verso.app',
        cover: 6,
        likes: 154,
        published: true,
        category: Category.letters,
        paperStock: PaperStock.fadedParchment,
        date: DateTime(2026, 11, 5),
        body: 'The radiator clicks three times before it warms.\nDon’t latches the east window too tightly—\nthe sparrows use the sill when it rains.',
      ),
      Piece(
        id: 'e12',
        title: 'Postcard from the breakwater',
        author: '@mara',
        ownerEmail: 'mara@verso.app',
        cover: 7,
        likes: 89,
        published: true,
        category: Category.letters,
        date: DateTime(2026, 10, 30),
        body: 'If you come in December, bring the heavy wool scarf.\nThe ferry still runs on Sundays,\nand the harbor master still remembers your dog.',
      ),
      Piece(
        id: 's1',
        title: 'Salt & Silence',
        author: '@ila',
        ownerEmail: 'ila@verso.app',
        cover: 2,
        likes: 64,
        published: true,
        audience: Audience.followers,
        body: 'Salt, and the silence after.\nWe stood where the tide gave up its shells.',
        extraPages: [
          'II.\nBy evening the gulls had gone.\nOnly the rope on the post kept speaking.',
          'III.\nKeep what the water returns;\nlet go of what it asks to keep.',
        ],
      ),
      Piece(
        id: 's2',
        title: 'Letters to the lake',
        author: '@ila',
        ownerEmail: 'ila@verso.app',
        cover: 1,
        likes: 39,
        published: true,
        category: Category.letters,
        audience: Audience.followers,
        body: 'Dear lake,\nyou were patient with every stone we threw.',
      ),
      Piece(
        id: 's3',
        title: 'What the boat knows',
        author: '@ila',
        ownerEmail: 'ila@verso.app',
        cover: 0,
        likes: 82,
        published: true,
        audience: Audience.followers,
        body: 'The boat knows\nthe weight of every leaving.',
      ),
      Piece(
        id: 's4',
        title: 'Untitled pages',
        author: '@ila',
        ownerEmail: 'ila@verso.app',
        cover: 3,
        published: false,
        body: 'The lantern on the pier is still warm',
      ),
    ]);

    bottles.addAll([
      DriftingBottle(
        id: 'b1',
        text: 'I walked along the breakwater until my coat was damp with salt. The light was almost purple.',
        location: 'North Harbor',
        author: 'A quiet traveler',
        castAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      DriftingBottle(
        id: 'b2',
        text: 'To whoever finds this: whatever you are hesitating to write, write it before the tide turns.',
        location: 'Pine Shallows',
        author: 'Lighthouse keeper',
        castAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DriftingBottle(
        id: 'b3',
        text: 'Left a smooth blue pebble on the bench under the pines. Hope it finds your pocket.',
        location: 'Island Pier',
        author: 'Island resident',
        castAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DriftingBottle(
        id: 'b4',
        text: 'The evening train sounded twice across the water. Everything went quiet again.',
        location: 'South Reach',
        author: 'Late walker',
        castAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);

    currentUser = users['ila@verso.app'];
  }

  void _loadFromDisk() {
    final raw = LocalStore.loadSync();
    if (raw == null) return;
    try {
      final uList = (raw['users'] as List?) ?? const [];
      if (uList.isNotEmpty) {
        users.clear();
        for (final item in uList) {
          final u = VersoUser.fromJson(Map<String, dynamic>.from(item as Map));
          users[u.email] = u;
        }
      }
      final pList = (raw['pieces'] as List?) ?? const [];
      if (pList.isNotEmpty) {
        allPieces
          ..clear()
          ..addAll(pList.map((e) => Piece.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      final bList = (raw['bottles'] as List?) ?? const [];
      if (bList.isNotEmpty) {
        bottles
          ..clear()
          ..addAll(bList.map((e) => DriftingBottle.fromJson(Map<String, dynamic>.from(e as Map))));
      }
      final activeEmail = raw['currentUserEmail'] as String?;
      if (activeEmail != null && users.containsKey(activeEmail)) {
        currentUser = users[activeEmail];
      } else if (raw.containsKey('currentUserEmail') && activeEmail == null) {
        currentUser = null;
      }
    } catch (_) {}
  }

  void _persistLocalOnly() {
    if (!enableDiskPersistence) return;
    LocalStore.saveSync({
      'users': users.values.map((u) => u.toJson()).toList(),
      'pieces': allPieces.map((p) => p.toJson()).toList(),
      'bottles': bottles.map((b) => b.toJson()).toList(),
      'currentUserEmail': currentUser?.email,
    });
  }

  void castBottle(String text, {String location = 'North Harbor'}) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final bottle = DriftingBottle(
      id: 'b_${DateTime.now().microsecondsSinceEpoch}',
      text: clean,
      location: location,
      author: activeUser.handle,
      castAt: DateTime.now(),
    );
    bottles.insert(0, bottle);
    _persistLocalOnly();
    notifyListeners();
  }

  DriftingBottle? uncorkRandomBottle() {
    if (bottles.isEmpty) return null;
    final b = bottles[DateTime.now().millisecond % bottles.length];
    b.uncorkCount++;
    _persistLocalOnly();
    notifyListeners();
    return b;
  }

  void _persist({VersoUser? changedUser, Piece? changedPiece, String? deletedPieceId}) {
    _persistLocalOnly();
    if (!enableDiskPersistence) return;
    if (changedUser != null) {
      unawaited(
        neon.upsertUser(changedUser).then((_) {
          neonSynced = true;
          notifyListeners();
        }).catchError((_) {}),
      );
    }
    if (changedPiece != null) {
      unawaited(
        neon.upsertPiece(changedPiece).then((_) {
          neonSynced = true;
          notifyListeners();
        }).catchError((_) {}),
      );
    }
    if (deletedPieceId != null) {
      unawaited(
        neon.deletePiece(deletedPieceId).then((_) {
          neonSynced = true;
          notifyListeners();
        }).catchError((_) {}),
      );
    }
  }

  static String _hash(String input) =>
      input.codeUnits.fold<int>(5381, (h, c) => ((h << 5) + h) ^ c).toRadixString(16);

  VersoUser get activeUser => currentUser ?? users.values.first;

  List<Piece> get exhibit => allPieces.where((p) {
        if (!p.published) return false;
        if (p.audience == Audience.exhibit) return true;
        if (p.audience == Audience.followers) {
          return p.ownerEmail == activeUser.email || activeUser.following.contains(p.author);
        }
        return false;
      }).toList();

  List<Piece> get shelf => allPieces.where((p) => p.ownerEmail == activeUser.email).toList();

  List<Piece> get savedPieces => allPieces.where((p) => p.isSavedBy(activeUser.email)).toList();

  Future<String?> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return 'Please enter your email.';
    if (password.trim().isEmpty) return 'Please enter your passphrase.';

    var user = users[cleanEmail];
    if (user == null && enableDiskPersistence) {
      // Attempt remote fetch from Neon in case account was created on another device
      try {
        final remoteUsers = await neon.fetchUsers();
        for (final ru in remoteUsers) {
          users[ru.email] = ru;
        }
        user = users[cleanEmail];
      } catch (_) {}
    }

    if (user == null) {
      return 'No account found for $cleanEmail.';
    }
    if (user.passwordHash != _hash(password.trim())) {
      return 'Incorrect passphrase. Try again.';
    }
    currentUser = user;
    tab = 0;
    _persist(changedUser: user);
    notifyListeners();
    return null;
  }

  Future<String?> signUp({
    required String name,
    required String handle,
    required String email,
    required String password,
    String bio = 'Leaving quiet pages by the water.',
    int avatarCover = 0,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return 'Enter a valid email address.';
    }
    final cleanPass = password.trim();
    if (cleanPass.length < 4) {
      return 'Passphrase should be at least 4 characters.';
    }

    // Refresh remote users so handle & email checks are authoritative against Neon
    if (enableDiskPersistence) {
      try {
        final remoteUsers = await neon.fetchUsers();
        for (final ru in remoteUsers) {
          users[ru.email] = ru;
        }
      } catch (_) {}
    }

    if (users.containsKey(cleanEmail)) {
      return 'An account with this email already exists.';
    }

    var cleanHandle = handle.trim().toLowerCase().replaceAll(' ', '');
    if (cleanHandle.isEmpty) {
      final raw = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      cleanHandle = '@${raw.isEmpty ? "writer" : raw}';
    }
    if (!cleanHandle.startsWith('@')) cleanHandle = '@$cleanHandle';

    if (cleanHandle == '@' || cleanHandle.length < 3) {
      return 'Handle should be at least 2 characters (e.g. @writer).';
    }

    final handleTaken = users.values.any((u) => u.handle.toLowerCase() == cleanHandle);
    if (handleTaken) {
      return 'Handle $cleanHandle is already taken. Please choose another.';
    }

    final cleanName = name.trim().isEmpty ? 'Writer' : name.trim();
    final cleanBio = bio.trim().isEmpty ? 'Leaving quiet pages by the water.' : bio.trim();

    final user = VersoUser(
      email: cleanEmail,
      passwordHash: _hash(cleanPass),
      name: cleanName,
      handle: cleanHandle,
      bio: cleanBio,
      avatarCover: avatarCover,
    );
    users[cleanEmail] = user;
    currentUser = user;

    final starterPiece = Piece(
      id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
      title: 'First page on the water',
      author: user.handle,
      ownerEmail: user.email,
      cover: avatarCover,
      published: false,
      body: 'I came to the quiet exhibit\nto leave a single line.',
    );
    allPieces.add(starterPiece);
    tab = 0;

    _persistLocalOnly();
    if (enableDiskPersistence) {
      try {
        await neon.upsertUser(user);
        await neon.upsertPiece(starterPiece);
        neonSynced = true;
      } catch (e) {
        neonSynced = false;
        return 'Could not save to database: ${neon.lastError ?? e.toString()}';
      }
    }
    notifyListeners();
    return null;
  }

  void signOut() {
    currentUser = null;
    tab = 0;
    _persistLocalOnly();
    notifyListeners();
  }

  /// Updates the active user's profile (name, @handle, bio, and emblem) and cascades @handle changes to all their pieces.
  Future<String?> updateProfile({String? name, String? handle, String? bio, int? avatarCover}) async {
    final u = activeUser;
    if (name != null && name.trim().isNotEmpty) {
      u.name = name.trim();
    }
    if (handle != null && handle.trim().isNotEmpty) {
      var clean = handle.trim().toLowerCase().replaceAll(' ', '');
      if (!clean.startsWith('@')) clean = '@$clean';
      final taken = users.values.any((other) => other.email != u.email && other.handle.toLowerCase() == clean);
      if (taken) {
        return 'Handle $clean is already taken.';
      }
      final oldHandle = u.handle;
      u.handle = clean;
      if (oldHandle != clean) {
        for (final p in allPieces) {
          if (p.ownerEmail == u.email) {
            p.author = clean;
            if (enableDiskPersistence) {
              unawaited(neon.upsertPiece(p).catchError((_) {}));
            }
          }
          for (var i = 0; i < p.notes.length; i++) {
            if (p.notes[i].fromHandle == oldHandle) {
              p.notes[i] = NoteReply(
                fromHandle: clean,
                text: p.notes[i].text,
                createdAt: p.notes[i].createdAt,
              );
            }
          }
        }
      }
    }
    if (bio != null) u.bio = bio.trim();
    if (avatarCover != null) u.avatarCover = avatarCover;
    _persistLocalOnly();
    if (enableDiskPersistence) {
      try {
        await neon.upsertUser(u);
        neonSynced = true;
      } catch (e) {
        neonSynced = false;
        return 'Could not save profile to database: ${neon.lastError ?? e.toString()}';
      }
    }
    notifyListeners();
    return null;
  }

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  bool isFollowing(String handle) => activeUser.following.contains(handle);

  void toggleFollow(String handle) {
    if (activeUser.following.contains(handle)) {
      activeUser.following.remove(handle);
    } else {
      activeUser.following.add(handle);
    }
    _persist(changedUser: activeUser);
    notifyListeners();
  }

  void toggleLike(Piece p) {
    final email = activeUser.email;
    if (p.likedBy.contains(email)) {
      p.likedBy.remove(email);
      p.likes = (p.likes - 1).clamp(0, 999999);
    } else {
      p.likedBy.add(email);
      p.likes += 1;
    }
    _persist(changedPiece: p);
    notifyListeners();
  }

  void toggleSave(Piece p) {
    final email = activeUser.email;
    if (p.savedBy.contains(email)) {
      p.savedBy.remove(email);
    } else {
      p.savedBy.add(email);
    }
    _persist(changedPiece: p);
    notifyListeners();
  }

  bool isLineHeld(Piece p, String line) =>
      activeUser.heldLines.any((h) => h.pieceId == p.id && h.line == line);

  bool toggleHoldLine(Piece p, String line) {
    final existingIdx = activeUser.heldLines.indexWhere((h) => h.pieceId == p.id && h.line == line);
    final bool held;
    if (existingIdx >= 0) {
      activeUser.heldLines.removeAt(existingIdx);
      held = false;
    } else {
      activeUser.heldLines.insert(
        0,
        HeldLine(
          line: line,
          pieceId: p.id,
          pieceTitle: p.title.isEmpty ? p.firstLine : p.title,
          author: p.author,
          cover: p.cover,
        ),
      );
      held = true;
    }
    _persist(changedUser: activeUser);
    notifyListeners();
    return held;
  }

  void removeHeldLine(HeldLine h) {
    activeUser.heldLines.remove(h);
    _persist(changedUser: activeUser);
    notifyListeners();
  }

  void addNote(Piece p, String text) {
    if (text.trim().isEmpty) return;
    p.notes.insert(0, NoteReply(fromHandle: activeUser.handle, text: text.trim()));
    _persist(changedPiece: p);
    notifyListeners();
  }

  Piece newDraft({String initialTitle = '', String initialBody = '', Category category = Category.poems}) {
    final u = activeUser;
    return Piece(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: initialTitle,
      body: initialBody,
      author: u.handle,
      ownerEmail: u.email,
      cover: u.avatarCover,
      category: category,
    );
  }

  void saveDraft(Piece p) {
    p.ownerEmail = activeUser.email;
    p.author = activeUser.handle;
    if (!allPieces.contains(p)) {
      allPieces.add(p);
    }
    _persist(changedPiece: p);
    notifyListeners();
  }

  void deletePiece(Piece p) {
    allPieces.remove(p);
    _persist(deletedPieceId: p.id);
    notifyListeners();
  }

  void unpublishPiece(Piece p) {
    p.published = false;
    _persist(changedPiece: p);
    notifyListeners();
  }

  void publish(Piece p) {
    p.published = true;
    p.ownerEmail = activeUser.email;
    p.author = activeUser.handle;
    if (p.title.trim().isEmpty) p.title = 'Untitled';
    allPieces.remove(p);
    allPieces.insert(0, p);
    tab = 0;
    _persist(changedPiece: p);
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
