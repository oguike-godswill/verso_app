import 'package:flutter/material.dart';
import '../art.dart';
import '../state.dart';
import '../theme.dart';
import 'profile_sheet.dart';
import 'shell.dart';

class PoemScreen extends StatefulWidget {
  final Piece piece;
  final VoidCallback? onEditPiece;
  const PoemScreen({super.key, required this.piece, this.onEditPiece});
  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  int _currentPage = 0;
  int? _readingLineIdx;

  void leaveNote() {
    final app = AppScope.of(context);
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VC.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(c).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave a note', style: serifStyle(24)),
            const SizedBox(height: 4),
            Text(
              'Short replies, never public comments.',
              style: sansStyle(12, color: VC.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 140,
              maxLines: 3,
              style: serifStyle(17),
              decoration: InputDecoration(
                hintText: 'Something quiet…',
                filled: true,
                fillColor: VC.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: VC.red,
                  padding: const EdgeInsets.all(15),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) {
                    app.addNote(widget.piece, text);
                  }
                  Navigator.pop(c);
                  if (text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note left on the water.')),
                    );
                  }
                },
                child: Text('Send note', style: sansStyle(14, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMoreMenu() {
    final app = AppScope.of(context);
    final p = widget.piece;
    final isMine = p.ownerEmail == app.activeUser.email;
    showModalBottomSheet(
      context: context,
      backgroundColor: VC.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_size_select_actual_outlined, color: VC.ink),
                title: Text('Share as Verso Postcard', style: sansStyle(14, weight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(c);
                  showSharePostcard(context, p);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined, color: VC.ink),
                title: Text('Printable Chapbook (8-Page Zine)', style: sansStyle(14, weight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(c);
                  showChapbookPrintModal(context, p);
                },
              ),
              if (isMine && widget.onEditPiece != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: VC.ink),
                  title: Text('Edit pages in Write', style: sansStyle(14, weight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(c);
                    Navigator.pop(context);
                    widget.onEditPiece!();
                  },
                ),
              if (isMine && p.published)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined, color: VC.ink),
                  title: Text('Move back to Drafts', style: sansStyle(14, weight: FontWeight.w600)),
                  onTap: () {
                    app.unpublishPiece(p);
                    Navigator.pop(c);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moved back to your Shelf drafts.')),
                    );
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: VC.red),
                  title: Text('Delete from Shelf', style: sansStyle(14, color: VC.red, weight: FontWeight.w600)),
                  onTap: () {
                    app.deletePiece(p);
                    Navigator.pop(c);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = widget.piece;
    final size = MediaQuery.sizeOf(context);
    final pages = p.allPages;
    final currentPageText = pages[_currentPage.clamp(0, pages.length - 1)];
    final paragraphs = currentPageText.split(RegExp(r'\n\s*\n'));
    final pageLines = currentPageText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final following = app.isFollowing(p.author);
    final liked = p.isLikedBy(app.activeUser.email);
    final saved = p.isSavedBy(app.activeUser.email);
    final stock = p.paperStock;
    final isMine = p.ownerEmail == app.activeUser.email;

    final catLabel = switch (p.category) {
      Category.poems => 'Poem',
      Category.journals => 'Journal',
      Category.letters => 'Letter',
    };
    final audLabel = switch (p.audience) {
      Audience.exhibit => 'Public Exhibit',
      Audience.followers => 'Followers',
      Audience.onlyMe => 'Private Shelf',
    };

    final paperTop = (size.height * 0.27).clamp(210.0, 255.0);
    final archW = (size.width * 0.46).clamp(160.0, 210.0);
    final archH = (archW * 1.25).clamp(190.0, 245.0);

    final paperBg = app.midnightLamp ? const Color(0xFF161F2E) : stock.bg;
    final paperFg = app.midnightLamp ? const Color(0xFFF6E8D5) : stock.fg;
    final paperRule = app.midnightLamp ? const Color(0x33F6E8D5) : stock.rule;

    return Scaffold(
      backgroundColor: app.midnightLamp ? VC.midnightBg : VC.blue,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arch artwork header with responsive size and attached "This week" badge
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: paperTop + 24,
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: archW,
                        height: archH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(200)),
                                border: Border.all(
                                  color: app.midnightLamp
                                      ? VC.lampAmber.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.22),
                                  width: 1.5,
                                ),
                              ),
                              child: Hero(
                                tag: 'art-${p.id}',
                                child: ArchArt(variant: p.cover, bottomCornerRadius: 0),
                              ),
                            ),
                            if (p.likes >= 100)
                              Positioned(
                                top: 14,
                                right: -10,
                                child: Transform.rotate(
                                  angle: 0.10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: VC.red,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'This week',
                                      style: sansStyle(10.5, color: Colors.white, weight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Paper sheet with torn top edge
              Positioned(
                top: paperTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipPath(
                  clipper: TornTopClipper(seed: 5, depth: 14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    color: paperBg,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        26,
                        32,
                        26,
                        230 + MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.title.isEmpty ? 'Untitled pages' : p.title,
                                style: serifStyle(29, color: paperFg, height: 1.18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ReadAloudPlayer(
                              lines: pageLines,
                              onActiveLineChanged: (idx) => setState(() => _readingLineIdx = idx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: VC.blue,
                              child: Text(
                                p.author.length > 1 ? p.author.substring(1, 2).toUpperCase() : 'I',
                                style: serifStyle(13, color: Colors.white, weight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.author, style: sansStyle(13, color: paperFg, weight: FontWeight.w700)),
                                  Text(
                                    '${p.date.day} ${months[p.date.month - 1]} · $catLabel · ${p.lines.length} lines · ${p.words}w',
                                    style: sansStyle(11, color: VC.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMine)
                              OutlinedButton(
                                onPressed: () => app.toggleFollow(p.author),
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  foregroundColor: following ? Colors.white : paperFg,
                                  backgroundColor: following ? VC.navy : Colors.transparent,
                                  side: BorderSide(color: paperFg.withValues(alpha: 0.6)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  following ? 'Following' : 'Follow',
                                  style: sansStyle(12, color: following ? Colors.white : paperFg, weight: FontWeight.w600),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: paperFg.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  audLabel,
                                  style: sansStyle(10.5, color: paperFg, weight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        if (pages.length > 1) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: paperFg.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text('CHAPBOOK PAGE ${_currentPage + 1} OF ${pages.length}', style: labelStyle()),
                                const Spacer(),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _currentPage > 0
                                      ? () {
                                          TactileAudio.playPaperTurn();
                                          setState(() => _currentPage--);
                                        }
                                      : null,
                                  icon: Icon(Icons.chevron_left, size: 18, color: paperFg),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _currentPage < pages.length - 1
                                      ? () {
                                          TactileAudio.playPaperTurn();
                                          setState(() => _currentPage++);
                                        }
                                      : null,
                                  icon: Icon(Icons.chevron_right, size: 18, color: paperFg),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Printable chapbook zine',
                                  onPressed: () => showChapbookPrintModal(context, p),
                                  icon: Icon(Icons.auto_stories_outlined, size: 16, color: paperFg),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Builder(
                          builder: (_) {
                            var lineCounter = 0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final para in paragraphs) ...[
                                  for (final line in para.split('\n').where((l) => l.trim().isNotEmpty))
                                    Builder(
                                      builder: (_) {
                                        final idx = lineCounter++;
                                        final held = app.isLineHeld(p, line);
                                        final reading = _readingLineIdx == idx;
                                        return GestureDetector(
                                          onLongPress: p.allowHold
                                              ? () {
                                                  final nowHeld = app.toggleHoldLine(p, line);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        nowHeld ? 'Held line: “$line”' : 'Removed from held lines',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 220),
                                            padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
                                            decoration: BoxDecoration(
                                              color: reading
                                                  ? VC.red.withValues(alpha: 0.18)
                                                  : (held ? VC.blue.withValues(alpha: 0.14) : Colors.transparent),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              line,
                                              style: serifStyle(
                                                18.5,
                                                color: paperFg,
                                                height: 1.55,
                                                weight: reading ? FontWeight.w600 : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 14),
                                ],
                              ],
                            );
                          },
                        ),
                        if (p.allowHold) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: paperFg.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: paperRule.withValues(alpha: 0.7)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.touch_app_outlined, size: 16, color: VC.muted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'TAP AND HOLD ANY LINE TO SAVE IT TO YOUR PROFILE.',
                                    style: labelStyle(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (p.notes.isNotEmpty) ...[
                          Divider(height: 32, color: paperRule),
                          Text('QUIET NOTES LEFT HERE', style: labelStyle()),
                          const SizedBox(height: 8),
                          for (final n in p.notes)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${n.fromHandle}: ', style: sansStyle(12, color: VC.muted, weight: FontWeight.w700)),
                                  Expanded(
                                    child: Text(n.text, style: serifStyle(15, color: paperFg, style: FontStyle.italic)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Pinned Top bar with Safe Area
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleBtn(
                          icon: Icons.chevron_left,
                          bg: VC.navy.withValues(alpha: 0.22),
                          fg: Colors.white,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        if (isMine && widget.onEditPiece != null) ...[
                          CircleBtn(
                            icon: Icons.edit_outlined,
                            bg: VC.navy.withValues(alpha: 0.22),
                            fg: Colors.white,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onEditPiece!();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        CircleBtn(
                          icon: app.midnightLamp ? Icons.lightbulb : Icons.lightbulb_outline,
                          bg: app.midnightLamp ? VC.lampAmber.withValues(alpha: 0.3) : VC.navy.withValues(alpha: 0.22),
                          fg: app.midnightLamp ? VC.lampAmber : Colors.white,
                          onTap: () {
                            app.toggleMidnightLamp();
                            TactileAudio.playQuillScratch();
                          },
                        ),
                        const SizedBox(width: 8),
                        CircleBtn(
                          icon: Icons.print_outlined,
                          bg: VC.navy.withValues(alpha: 0.22),
                          fg: Colors.white,
                          onTap: () => showChapbookPrintModal(context, p),
                        ),
                        const SizedBox(width: 8),
                        CircleBtn(
                          icon: saved ? Icons.bookmark : Icons.bookmark_border,
                          bg: VC.navy.withValues(alpha: 0.22),
                          fg: Colors.white,
                          onTap: () => app.toggleSave(p),
                        ),
                        const SizedBox(width: 8),
                        CircleBtn(
                          icon: Icons.more_horiz,
                          bg: VC.navy.withValues(alpha: 0.22),
                          fg: Colors.white,
                          onTap: showMoreMenu,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action button bar + floating nav bar pinned cleanly at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 1.0],
                      colors: [
                        paperBg.withValues(alpha: 0.0),
                        paperBg.withValues(alpha: 0.94),
                        paperBg,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => app.toggleLike(p),
                                icon: Icon(
                                  liked ? Icons.favorite : Icons.favorite_border,
                                  size: 16,
                                  color: liked ? VC.red : VC.ink,
                                ),
                                label: Text('${p.likes}', style: sansStyle(13, color: VC.ink, weight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  backgroundColor: VC.cream,
                                  side: BorderSide(color: VC.muted.withValues(alpha: 0.45)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: p.allowNotes ? leaveNote : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: VC.red,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    'Leave a note',
                                    style: sansStyle(13.5, color: Colors.white, weight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: VC.muted.withValues(alpha: 0.45)),
                                ),
                                child: CircleBtn(
                                  icon: Icons.ios_share,
                                  bg: VC.cream,
                                  fg: VC.ink,
                                  onTap: () => showSharePostcard(context, p),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          VersoNavBar(
                            index: 0,
                            onTap: (tabIdx) {
                              Navigator.pop(context);
                              if (tabIdx != 0) {
                                app.setTab(tabIdx);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showChapbookPrintModal(BuildContext context, Piece piece) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: VC.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (c) => _ChapbookPrintSheet(piece: piece),
  );
}

class _ChapbookPrintSheet extends StatefulWidget {
  final Piece piece;
  const _ChapbookPrintSheet({required this.piece});

  @override
  State<_ChapbookPrintSheet> createState() => _ChapbookPrintSheetState();
}

class _ChapbookPrintSheetState extends State<_ChapbookPrintSheet> {
  int _view = 0; // 0 = Sheet 2x4, 1 = Booklet flip
  int _bookletPage = 1; // 1 to 8

  List<String> _build8Pages(Piece p) {
    final lines = p.lines;
    final pages = <String>[];
    // Page 1: Cover
    pages.add('MARGINALIA PRESS\n\n${p.title.isEmpty ? p.firstLine : p.title}\n\nby ${p.author}');

    // Split body lines across pages 2..7
    final bodyLines = lines.length > 1 ? lines.sublist(1) : lines;
    final chunkSize = (bodyLines.length / 5).ceil().clamp(1, 8);
    for (var i = 0; i < 5; i++) {
      final start = i * chunkSize;
      if (start < bodyLines.length) {
        final end = (start + chunkSize).clamp(0, bodyLines.length);
        pages.add(bodyLines.sublist(start, end).join('\n'));
      } else {
        pages.add('· · ·');
      }
    }

    // Page 7: Notes or closing line
    if (p.notes.isNotEmpty) {
      pages.add('Echo on the water:\n\n“${p.notes.first.text}”\n— ${p.notes.first.fromHandle}');
    } else {
      pages.add('“The page keeps what the water forgives.”');
    }

    // Page 8: Colophon (Back cover)
    pages.add(
      'MARGINALIA COMMONPLACE\n\n'
      'Printed along the north shore.\n'
      '${p.lines.length} lines · ${p.words} words\n'
      '${p.date.day} ${months[p.date.month - 1]} ${p.date.year}\n\n'
      'Fold along dotted lines.\nKeep by the water.',
    );

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.piece;
    final pages = _build8Pages(p);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VC.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.auto_stories, size: 22, color: VC.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('8-Page Pocket Chapbook', style: serifStyle(22)),
                        Text(
                          'Foldable single-sheet mini-zine layout',
                          style: sansStyle(12, color: VC.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: VC.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PillTabs(
                labels: const ['Sheet Fold (2×4)', 'Flip Booklet (1–8)'],
                index: _view,
                onChanged: (i) {
                  TactileAudio.playPaperTurn();
                  setState(() => _view = i);
                },
              ),
              const SizedBox(height: 16),

              if (_view == 0) ...[
                // 2x4 printable foldable sheet layout
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VC.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VC.paperDark, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // Top Row: Page 8 (Back), Page 1 (Front), Page 2, Page 3
                      Row(
                        children: [
                          _buildZinePanel(8, 'Back Cover', pages[7]),
                          _buildZinePanel(1, 'Front Cover', pages[0], isCover: true),
                          _buildZinePanel(2, 'Page 2', pages[1]),
                          _buildZinePanel(3, 'Page 3', pages[2]),
                        ],
                      ),
                      // Center cut & fold line guide
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Expanded(child: Divider(color: VC.muted, thickness: 1)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: VC.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.content_cut, size: 12, color: VC.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    'CUT CENTER SLIT',
                                    style: sansStyle(9, color: VC.red, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const Expanded(child: Divider(color: VC.muted, thickness: 1)),
                          ],
                        ),
                      ),
                      // Bottom Row: Page 7, Page 6, Page 5, Page 4
                      Row(
                        children: [
                          _buildZinePanel(7, 'Page 7', pages[6]),
                          _buildZinePanel(6, 'Page 6', pages[5]),
                          _buildZinePanel(5, 'Page 5', pages[4]),
                          _buildZinePanel(4, 'Page 4', pages[3]),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'FOLDING INSTRUCTIONS: Fold the paper into 8 panels (half lengthwise, then half twice). '
                  'Slit the center fold between pages 2-3 and 6-5. Push from both ends outward and fold into an 8-page book.',
                  style: sansStyle(11, color: VC.muted, height: 1.4),
                ),
              ] else ...[
                // Interactive booklet flip preview
                Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: VC.paper,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('PAGE $_bookletPage OF 8', style: labelStyle(color: VC.red)),
                          const Spacer(),
                          Text(
                            _bookletPage == 1 ? 'Cover' : (_bookletPage == 8 ? 'Colophon' : 'Interior'),
                            style: sansStyle(11, color: VC.muted, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            pages[_bookletPage - 1],
                            style: _bookletPage == 1 || _bookletPage == 8
                                ? sansStyle(12, height: 1.45, weight: FontWeight.w600)
                                : serifStyle(16, height: 1.35),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: VC.ink),
                            onPressed: _bookletPage > 1
                                ? () {
                                    TactileAudio.playPaperTurn();
                                    setState(() => _bookletPage--);
                                  }
                                : null,
                          ),
                          Text(
                            '$_bookletPage / 8',
                            style: sansStyle(12, color: VC.muted, weight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: VC.ink),
                            onPressed: _bookletPage < 8
                                ? () {
                                    TactileAudio.playPaperTurn();
                                    setState(() => _bookletPage++);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: VC.navy),
                      ),
                      onPressed: () {
                        TactileAudio.playQuillScratch();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chapbook text prepared. Ready to print or bind.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined, size: 16, color: VC.navy),
                      label: Text(
                        'Copy zine text',
                        style: sansStyle(12.5, color: VC.navy, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: VC.red,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        TactileAudio.playPaperTurn();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Foldable 8-page chapbook “${p.title.isEmpty ? p.firstLine : p.title}” ready.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: Text(
                        'Done',
                        style: sansStyle(12.5, color: Colors.white, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZinePanel(int num, String label, String content, {bool isCover = false}) {
    return Expanded(
      child: Container(
        height: 82,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCover ? VC.cream : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCover ? VC.red.withValues(alpha: 0.4) : VC.paperDark,
            width: isCover ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$num', style: sansStyle(9, color: isCover ? VC.red : VC.muted, weight: FontWeight.w700)),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    label,
                    style: sansStyle(7.5, color: VC.muted),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: isCover
                    ? sansStyle(7.5, color: VC.navy, weight: FontWeight.w700, height: 1.1)
                    : serifStyle(8, color: VC.ink, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
