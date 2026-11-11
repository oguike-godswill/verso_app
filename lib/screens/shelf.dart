import 'package:flutter/material.dart';
import '../art.dart';
import '../state.dart';
import '../theme.dart';
import 'poem.dart';
import 'profile_sheet.dart';
import 'shell.dart';

class ShelfScreen extends StatefulWidget {
  final ValueChanged<Piece> onOpenDraft;
  const ShelfScreen({super.key, required this.onOpenDraft});
  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.activeUser;
    final items = app.shelf.where((p) => filter == 0 || (filter == 1 ? p.published : !p.published)).toList();

    return Container(
      color: VC.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR  ·  ${user.handle.toUpperCase()}', style: labelStyle()),
                        const SizedBox(height: 2),
                        Text('Shelf', style: serifStyle(40, height: 1.1)),
                      ],
                    ),
                  ),
                  CircleBtn(
                    icon: Icons.person_outline,
                    bg: VC.paperDark,
                    fg: VC.ink,
                    onTap: () => showProfileSheet(context),
                  ),
                  const SizedBox(width: 8),
                  CircleBtn(
                    icon: Icons.edit_outlined,
                    bg: VC.paperDark,
                    fg: VC.ink,
                    onTap: () => widget.onOpenDraft(app.newDraft()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                children: [
                  PillTabs(
                    labels: const ['All', 'Published', 'Drafts'],
                    index: filter,
                    onChanged: (i) => setState(() => filter = i),
                  ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.45,
              children: [
                for (final p in items)
                  _Book(
                    piece: p,
                    onTap: () => _open(p),
                    onLongPress: () => _showBookDetailsSheet(p),
                  ),
                _NewBook(onTap: () => widget.onOpenDraft(app.newDraft())),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),
);
}

  void _open(Piece p) {
    if (p.published) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PoemScreen(
            piece: p,
            onEditPiece: () => widget.onOpenDraft(p),
          ),
        ),
      );
    } else {
      widget.onOpenDraft(p);
    }
  }

  void _showBookDetailsSheet(Piece p) {
    final app = AppScope.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: VC.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 48, height: 58, child: ArchArt(variant: p.cover)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title.isEmpty ? 'Untitled pages' : p.title,
                          style: serifStyle(22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.author}  ·  ${p.published ? "Published" : "Draft"}  ·  ${p.words} words  ·  ${p.pageCount}p',
                          style: sansStyle(11.5, color: VC.muted, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined, color: VC.ink),
                title: Text('Read book', style: sansStyle(14, weight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(c);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PoemScreen(
                        piece: p,
                        onEditPiece: () => widget.onOpenDraft(p),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined, color: VC.ink),
                title: Text('Edit pages in Write', style: sansStyle(14, weight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(c);
                  widget.onOpenDraft(p);
                },
              ),
              if (p.published)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_off_outlined, color: VC.ink),
                  title: Text('Move back to Drafts', style: sansStyle(14, weight: FontWeight.w600)),
                  onTap: () {
                    app.unpublishPiece(p);
                    Navigator.pop(c);
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline, color: VC.red),
                title: Text('Delete from Shelf', style: sansStyle(14, color: VC.red, weight: FontWeight.w600)),
                onTap: () {
                  app.deletePiece(p);
                  Navigator.pop(c);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Book extends StatelessWidget {
  final Piece piece;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Book({required this.piece, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final bg = switch (piece.cover % 4) {
      0 => VC.cream,
      1 => VC.navy,
      2 => VC.blue,
      _ => VC.blue,
    };

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(2, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(width: 5, color: Colors.black.withValues(alpha: 0.14)), // book spine crease
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 12, 22),
                      child: ArchArt(variant: piece.cover, bottomCornerRadius: 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            piece.title.isEmpty ? 'Untitled pages' : piece.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: serifStyle(14, height: 1.15),
          ),
          const SizedBox(height: 2),
          Text(
            piece.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sansStyle(10.5, color: VC.muted, weight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece.published ? VC.navy : VC.red,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  piece.published
                      ? (piece.pageCount > 1 ? 'Published · ${piece.pageCount}p' : 'Published')
                      : (piece.pageCount > 1 ? 'Draft · ${piece.pageCount}p' : 'Draft'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sansStyle(
                    9.5,
                    color: piece.published ? VC.muted : VC.red,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewBook extends StatelessWidget {
  final VoidCallback onTap;
  const _NewBook({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 0.72,
              child: CustomPaint(
                painter: _DashedBorder(),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: VC.muted, size: 20),
                      const SizedBox(height: 4),
                      Text('New book', style: sansStyle(11, color: VC.muted, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = VC.muted.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(7)));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 8) {
        c.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
