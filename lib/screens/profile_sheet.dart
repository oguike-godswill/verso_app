import 'package:flutter/material.dart';
import '../art.dart';
import '../state.dart';
import '../theme.dart';
import 'auth.dart';
import 'poem.dart';
import 'shell.dart';

void showProfileSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();
  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  bool editingProfile = false;
  late TextEditingController nameCtrl;
  late TextEditingController handleCtrl;
  late TextEditingController bioCtrl;
  int selectedEmblem = 0;
  String? errorMsg;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final u = AppScope.of(context).activeUser;
      nameCtrl = TextEditingController(text: u.name);
      handleCtrl = TextEditingController(text: u.handle);
      bioCtrl = TextEditingController(text: u.bio);
      selectedEmblem = u.avatarCover;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    handleCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    final app = AppScope.of(context);
    final err = await app.updateProfile(
      name: nameCtrl.text,
      handle: handleCtrl.text,
      bio: bioCtrl.text,
      avatarCover: selectedEmblem,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        errorMsg = err;
      });
      return;
    }
    setState(() {
      _saving = false;
      errorMsg = null;
      editingProfile = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved and synced to database.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final u = app.activeUser;
    final myPieces = app.shelf;
    final publishedCount = myPieces.where((p) => p.published).length;
    final totalLikes = myPieces.fold<int>(0, (sum, p) => sum + p.likes);
    final totalNotes = myPieces.fold<int>(0, (sum, p) => sum + p.notes.length);
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = bottomInset > 0;

    return ClipPath(
      clipper: TornTopClipper(seed: 14, depth: 12),
      child: Container(
        color: VC.cream,
        constraints: BoxConstraints(maxHeight: size.height * (isKeyboardOpen ? 0.94 : 0.86)),
        padding: EdgeInsets.fromLTRB(24, isKeyboardOpen ? 18 : 30, 24, bottomInset + 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 62,
                  child: ArchArt(variant: editingProfile ? selectedEmblem : u.avatarCover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: serifStyle(26)),
                      Text('${u.handle} · ${u.email}', style: sansStyle(12, color: VC.muted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => setState(() {
                    editingProfile = !editingProfile;
                    nameCtrl.text = u.name;
                    handleCtrl.text = u.handle;
                    bioCtrl.text = u.bio;
                    selectedEmblem = u.avatarCover;
                    errorMsg = null;
                  }),
                  style: IconButton.styleFrom(backgroundColor: VC.paper),
                  icon: Icon(editingProfile ? Icons.close : Icons.edit_outlined, size: 17, color: VC.ink),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  },
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text('Switch', style: sansStyle(12, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VC.ink,
                    side: const BorderSide(color: VC.paperDark),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (editingProfile)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VC.paper,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EDIT PROFILE', style: labelStyle()),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _editField(label: 'NAME', controller: nameCtrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _editField(label: 'HANDLE', controller: handleCtrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _editField(label: 'BIO', controller: bioCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    Text('EMBLEM', style: labelStyle()),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kArchVariantCount,
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setState(() => selectedEmblem = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            width: 46,
                            height: 54,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28),
                                bottom: Radius.circular(6),
                              ),
                              border: Border.all(
                                color: selectedEmblem == i ? VC.red : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ArchArt(variant: i),
                          ),
                        ),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMsg!, style: sansStyle(12, color: VC.red, weight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: VC.navy,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _saving ? null : _saveProfile,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Save profile', style: sansStyle(13, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () => setState(() => editingProfile = true),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '“${u.bio}”',
                        style: serifStyle(15, color: VC.ink, style: FontStyle.italic),
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 14, color: VC.muted),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: VC.paper,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('$publishedCount', 'Published'),
                  _stat('${myPieces.length - publishedCount}', 'Drafts'),
                  _stat('$totalLikes', 'Likes'),
                  _stat('$totalNotes', 'Notes'),
                  _stat('${u.heldLines.length}', 'Held lines'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('LINES YOU HOLD', style: labelStyle()),
            const SizedBox(height: 8),
            if (u.heldLines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Long-press any line in a poem to keep it in your commonplace book.',
                  style: serifStyle(15, color: VC.muted, style: FontStyle.italic),
                ),
              )
            else
              for (final h in u.heldLines)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VC.paper,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('“${h.line}”', style: serifStyle(16, style: FontStyle.italic)),
                            const SizedBox(height: 4),
                            Text('${h.pieceTitle} · ${h.author}', style: sansStyle(11, color: VC.muted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: VC.muted),
                        onPressed: () => app.removeHeldLine(h),
                      ),
                    ],
                  ),
                ),
            if (app.savedPieces.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('BOOKMARKED EXHIBITS', style: labelStyle()),
              const SizedBox(height: 8),
              for (final p in app.savedPieces)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(width: 34, height: 40, child: ArchArt(variant: p.cover)),
                  title: Text(p.title, style: serifStyle(17)),
                  subtitle: Text(p.author, style: sansStyle(11, color: VC.muted)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PoemScreen(piece: p)));
                  },
                ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      app.signOut();
                      Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VC.red,
                      side: const BorderSide(color: VC.red),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                    child: Text('Sign out', style: sansStyle(13, color: VC.red, weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField({required String label, required TextEditingController controller, int maxLines = 1}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle()),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: sansStyle(13.5, weight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: VC.cream,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );

  Widget _stat(String val, String label) => Column(
        children: [
          Text(val, style: serifStyle(22, weight: FontWeight.w600)),
          Text(label, style: sansStyle(10, color: VC.muted, weight: FontWeight.w600)),
        ],
      );
}

/// Shareable "Verso Postcard" preview modal when sharing a poem or held line.
void showSharePostcard(BuildContext context, Piece piece) {
  showDialog(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 310,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: VC.cream,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(160), bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 165,
                  width: 155,
                  child: ArchArt(variant: piece.cover, showInnerFrame: true),
                ),
                const SizedBox(height: 16),
                Text(piece.title, textAlign: TextAlign.center, style: serifStyle(24)),
                const SizedBox(height: 10),
                Text(
                  '“${piece.lines.take(4).join('\n')}”',
                  textAlign: TextAlign.center,
                  style: serifStyle(15, style: FontStyle.italic, height: 1.5),
                ),
                const SizedBox(height: 14),
                Text(
                  '${piece.author.toUpperCase()}  ·  VERSO EXHIBIT',
                  style: labelStyle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: VC.red,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                ),
                onPressed: () {
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Postcard link copied to clipboard.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text('Copy postcard link', style: sansStyle(13, color: Colors.white, weight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              CircleBtn(
                icon: Icons.close,
                bg: Colors.white24,
                onTap: () => Navigator.pop(c),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
