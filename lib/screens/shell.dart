import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import 'exhibit.dart';
import 'write.dart';
import 'shelf.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Piece? editing;

  void _openPromptInWrite(String prompt) {
    final app = AppScope.of(context);
    setState(() {
      editing = app.newDraft(
        initialTitle: '',
        initialBody: '$prompt\n\n',
      );
      app.setTab(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: app.tab,
        children: [
          ExhibitScreen(onStartWithPrompt: _openPromptInWrite),
          editing == null
              ? const SizedBox()
              : WriteScreen(
                  key: ValueKey(editing!.id),
                  piece: editing!,
                  onClose: () => setState(() {
                    editing = null;
                    app.setTab(2);
                  }),
                  onPublished: () => setState(() => editing = null),
                ),
          ShelfScreen(
            onOpenDraft: (p) => setState(() {
              editing = p;
              app.setTab(1);
            }),
          ),
        ],
      ),
      bottomNavigationBar: VersoNavBar(
        index: app.tab,
        onTap: (i) {
          if (i == 1 && editing == null) editing = app.newDraft();
          app.setTab(i);
        },
      ),
    );
  }
}

class VersoNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const VersoNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.account_balance_outlined, 'Exhibit'),
      (Icons.edit_outlined, 'Write'),
      (Icons.menu_book_outlined, 'Shelf'),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: VC.cream,
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: i == index ? VC.navy : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1, size: 18, color: i == index ? Colors.white : VC.muted),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: sansStyle(
                            10.5,
                            color: i == index ? Colors.white : VC.muted,
                            weight: i == index ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable segmented pill tabs (All/Published/Drafts, Poems/Journals/Letters...)
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool? onBlue;
  const PillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.onBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    final blueMode = onBlue == true;
    final bg = blueMode ? Colors.white.withValues(alpha: 0.13) : VC.paperDark;
    final sel = blueMode ? VC.cream : VC.navy;
    final selText = blueMode ? VC.ink : Colors.white;
    final text = blueMode ? Colors.white.withValues(alpha: 0.85) : VC.muted;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(21)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? sel : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    labels[i],
                    style: sansStyle(
                      12.5,
                      color: i == index ? selText : text,
                      weight: i == index ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  const CircleBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.bg = const Color(0x22FFFFFF),
    this.fg = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: fg)),
        ),
      );
}
