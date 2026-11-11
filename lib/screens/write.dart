import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import 'publish.dart';

class WriteScreen extends StatefulWidget {
  final Piece piece;
  final VoidCallback onClose;
  final VoidCallback onPublished;
  const WriteScreen({super.key, required this.piece, required this.onClose, required this.onPublished});
  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  late final title = TextEditingController(text: widget.piece.title);
  late final body = TextEditingController(text: widget.piece.body);
  final history = <String>[];
  final future = <String>[];
  bool saved = true;
  bool bold = false, italic = false;
  double fontSize = 18;
  int promptIdx = 0;
  int activePageIdx = 0; // 0 = main body, 1..n = extraPages[i - 1]
  Soundscape soundscape = Soundscape.off;

  @override
  void initState() {
    super.initState();
    history.add(body.text);
    body.addListener(_onBody);
    title.addListener(() {
      widget.piece.title = title.text;
      setState(() => saved = true);
    });
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  void _syncActivePageToPiece() {
    if (activePageIdx == 0) {
      widget.piece.body = body.text;
    } else {
      final idx = activePageIdx - 1;
      if (idx >= 0 && idx < widget.piece.extraPages.length) {
        widget.piece.extraPages[idx] = body.text;
      }
    }
  }

  void _switchPage(int newIdx) {
    TactileAudio.playPaperTurn();
    _syncActivePageToPiece();
    setState(() {
      activePageIdx = newIdx;
      final text = newIdx == 0 ? widget.piece.body : widget.piece.extraPages[newIdx - 1];
      body.removeListener(_onBody);
      body.text = text;
      body.addListener(_onBody);
      history
        ..clear()
        ..add(text);
      future.clear();
    });
  }

  void _addChapbookPage() {
    TactileAudio.playPaperTurn();
    _syncActivePageToPiece();
    widget.piece.extraPages.add('');
    _switchPage(widget.piece.extraPages.length);
  }

  void _onBody() {
    if (history.isEmpty || history.last != body.text) {
      history.add(body.text);
      future.clear();
      _syncActivePageToPiece();
      setState(() => saved = true);
    } else {
      setState(() {});
    }
  }

  void undo() {
    if (history.length < 2) return;
    future.add(history.removeLast());
    _set(history.last);
  }

  void redo() {
    if (future.isEmpty) return;
    final t = future.removeLast();
    history.add(t);
    _set(t);
  }

  void _set(String t) {
    body.removeListener(_onBody);
    body.text = t;
    _syncActivePageToPiece();
    body.addListener(_onBody);
    setState(() {});
  }

  void insertLineBreak() {
    final sel = body.selection;
    final offset = sel.isValid ? sel.end : body.text.length;
    final t = body.text.replaceRange(offset, offset, '\n\n');
    body.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: offset + 2));
  }

  void cycleCategory() {
    final nextIdx = (widget.piece.category.index + 1) % Category.values.length;
    setState(() => widget.piece.category = Category.values[nextIdx]);
  }

  void cyclePaperStock() {
    final nextIdx = (widget.piece.paperStock.index + 1) % PaperStock.values.length;
    setState(() => widget.piece.paperStock = PaperStock.values[nextIdx]);
  }

  void sparkPrompt() {
    final prompt = dailyPrompts[promptIdx % dailyPrompts.length];
    promptIdx++;
    if (title.text.trim().isEmpty) {
      title.text = prompt;
      widget.piece.title = prompt;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prompt: “$prompt”')),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final d = widget.piece.date;
    final stock = widget.piece.paperStock;
    final hasSelection = body.selection.isValid && !body.selection.isCollapsed;
    final style = serifStyle(
      fontSize,
      color: stock.fg,
      height: 1.9,
      weight: bold ? FontWeight.w700 : FontWeight.w400,
      style: italic ? FontStyle.italic : FontStyle.normal,
    );
    final catSingular = switch (widget.piece.category) {
      Category.poems => 'POEM',
      Category.journals => 'JOURNAL',
      Category.letters => 'LETTER',
    };
    final totalPages = 1 + widget.piece.extraPages.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      color: stock.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _syncActivePageToPiece();
                      app.saveDraft(widget.piece);
                      widget.onClose();
                    },
                    style: IconButton.styleFrom(backgroundColor: VC.paperDark),
                    icon: const Icon(Icons.close, size: 18, color: VC.ink),
                  ),
                  const SizedBox(width: 8),
                  SoundscapeBadge(
                    active: soundscape,
                    onChanged: (s) => setState(() => soundscape = s),
                  ),
                  const Spacer(),
                  Text(
                    saved ? 'Draft · saved' : 'Saving…',
                    style: sansStyle(12, color: VC.muted, weight: FontWeight.w600),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: VC.red,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: widget.piece.words == 0 && body.text.trim().isEmpty
                        ? null
                        : () async {
                            _syncActivePageToPiece();
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => PublishScreen(piece: widget.piece)),
                            );
                            if (ok == true) widget.onPublished();
                          },
                    child: Text('Publish', style: sansStyle(13, color: Colors.white, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 180),
                children: [
                  TextField(
                    controller: title,
                    style: serifStyle(34, color: stock.fg),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Untitled',
                      hintStyle: serifStyle(34, color: VC.muted.withValues(alpha: 0.5)),
                      isCollapsed: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: cycleCategory,
                        child: Text(
                          '${d.day} ${months[d.month - 1].toUpperCase()}  ·  $catSingular',
                          style: labelStyle(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more, size: 13, color: VC.muted),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: sparkPrompt,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.auto_awesome_outlined, size: 14, color: VC.blue),
                        label: Text('Prompt', style: sansStyle(11.5, color: VC.blue, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  // Chapbook multi-page strip
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < totalPages; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('Page ${i + 1}', style: sansStyle(11, weight: FontWeight.w700)),
                              selected: activePageIdx == i,
                              onSelected: (_) => _switchPage(i),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: Text('Add page', style: sansStyle(11, weight: FontWeight.w600)),
                          visualDensity: VisualDensity.compact,
                          onPressed: _addChapbookPage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _RulePainter(fontSize * 1.9, stock.rule))),
                      TextField(
                        controller: body,
                        maxLines: null,
                        minLines: 12,
                        style: style,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: 'Begin with a single line…',
                          hintStyle: serifStyle(fontSize, color: VC.muted.withValues(alpha: 0.55), height: 1.9),
                        ),
                      ),
                    ],
                  ),
                  if (hasSelection || bold || italic)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: VC.navy, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _fmt('B', bold, () => setState(() => bold = !bold), w: FontWeight.w800),
                            _fmt('I', italic, () => setState(() => italic = !italic), s: FontStyle.italic),
                            _fmt('Line', false, insertLineBreak),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Editor toolbar (sits above floating nav)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 90),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: VC.navy, borderRadius: BorderRadius.circular(23)),
                child: Row(
                  children: [
                    _tool(Icons.text_fields, () => setState(() => fontSize = fontSize >= 22 ? 16 : fontSize + 2)),
                    _tool(Icons.palette_outlined, cyclePaperStock),
                    _tool(Icons.image_outlined, () {
                      setState(() => widget.piece.cover = (widget.piece.cover + 1) % 8);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cover #${widget.piece.cover + 1} selected')),
                      );
                    }),
                    _tool(Icons.undo, undo),
                    _tool(Icons.redo, redo),
                    const Spacer(),
                    Text(
                      '${stock.label} · ${widget.piece.words} words',
                      style: sansStyle(11.5, color: Colors.white70, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tool(IconData i, VoidCallback f) =>
      IconButton(onPressed: f, icon: Icon(i, size: 18, color: Colors.white), visualDensity: VisualDensity.compact);

  Widget _fmt(String t, bool on, VoidCallback f, {FontWeight w = FontWeight.w600, FontStyle s = FontStyle.normal}) =>
      TextButton(
        onPressed: f,
        style: TextButton.styleFrom(foregroundColor: on ? VC.red : Colors.white, minimumSize: const Size(36, 34)),
        child: Text(t, style: TextStyle(fontFamily: sansFont, fontWeight: w, fontStyle: s, fontSize: 12)),
      );
}

class _RulePainter extends CustomPainter {
  final double lh;
  final Color color;
  _RulePainter(this.lh, this.color);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double y = lh - 4; y < s.height; y += lh) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_RulePainter o) => o.lh != lh || o.color != color;
}
