import 'package:flutter/material.dart';
import '../art.dart';
import '../state.dart';
import '../theme.dart';
import 'poem.dart';
import 'profile_sheet.dart';
import 'shell.dart';

class ExhibitScreen extends StatefulWidget {
  final ValueChanged<String>? onStartWithPrompt;
  const ExhibitScreen({super.key, this.onStartWithPrompt});
  @override
  State<ExhibitScreen> createState() => _ExhibitScreenState();
}

class _ExhibitScreenState extends State<ExhibitScreen> {
  int cat = 0;
  String query = '';
  bool searching = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bgColor = app.midnightLamp ? VC.midnightBg : VC.blue;
    final items = app.exhibit
        .where((p) => p.category == Category.values[cat])
        .where((p) => query.isEmpty || '${p.title} ${p.body} ${p.author}'.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixed top bar with aligned Title and action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Exhibit',
                          style: serifStyle(
                            40,
                            color: app.midnightLamp ? VC.lampAmber : Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      CircleBtn(
                        icon: app.midnightLamp ? Icons.lightbulb : Icons.lightbulb_outline,
                        bg: app.midnightLamp ? VC.lampAmber.withValues(alpha: 0.3) : const Color(0x22FFFFFF),
                        fg: app.midnightLamp ? VC.lampAmber : Colors.white,
                        onTap: () {
                          app.toggleMidnightLamp();
                          TactileAudio.playQuillScratch();
                        },
                      ),
                      const SizedBox(width: 8),
                      CircleBtn(
                        icon: Icons.waves_outlined,
                        onTap: () => showDriftingBottlesModal(context),
                      ),
                      const SizedBox(width: 8),
                      CircleBtn(
                        icon: searching ? Icons.close : Icons.search,
                        onTap: () => setState(() {
                          searching = !searching;
                          query = '';
                        }),
                      ),
                      const SizedBox(width: 8),
                      CircleBtn(
                        icon: Icons.person_outline,
                        onTap: () => showProfileSheet(context),
                      ),
                    ],
                  ),
                  if (searching) ...[
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => query = v),
                      style: sansStyle(14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search lines, titles, people',
                        hintStyle: sansStyle(14, color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Scrollable exhibit gallery underneath
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PillTabs(
                            labels: const ['Poems', 'Journals', 'Letters'],
                            index: cat,
                            onBlue: true,
                            onChanged: (i) => setState(() => cat = i),
                          ),
                          const SizedBox(height: 14),
                          _WaxSealedPromptCard(onStartWithPrompt: widget.onStartWithPrompt),
                          const SizedBox(height: 10),
                          _DriftingBottlePill(onTap: () => showDriftingBottlesModal(context)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverToBoxAdapter(child: _Staggered(items: items)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  final List<Piece> items;
  const _Staggered({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            'Nothing hanging here yet.',
            style: serifStyle(19, color: Colors.white70, style: FontStyle.italic),
          ),
        ),
      );
    }
    final left = <Piece>[], right = <Piece>[];
    for (var i = 0; i < items.length; i++) {
      (i.isEven ? left : right).add(items[i]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: [for (final p in left) ExhibitCard(piece: p)])),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 24),
              for (final p in right) ExhibitCard(piece: p),
            ],
          ),
        ),
      ],
    );
  }
}

class ExhibitCard extends StatelessWidget {
  final Piece piece;
  const ExhibitCard({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final liked = piece.isLikedBy(app.activeUser.email);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, a, _) => FadeTransition(opacity: a, child: PoemScreen(piece: piece)),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
        decoration: BoxDecoration(
          color: VC.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(200), bottom: Radius.circular(16)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.08,
              child: Hero(tag: 'art-${piece.id}', child: ArchArt(variant: piece.cover)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 11, 7, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.firstLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: serifStyle(16, style: FontStyle.italic, height: 1.25),
                  ),
                  if (piece.title.trim().isNotEmpty &&
                      piece.title.trim().toLowerCase() != piece.firstLine.trim().toLowerCase()) ...[
                    const SizedBox(height: 3),
                    Text(
                      piece.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sansStyle(10.5, color: VC.ink.withValues(alpha: 0.7), weight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          piece.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sansStyle(11.5, color: VC.muted, weight: FontWeight.w700),
                        ),
                      ),
                      Icon(liked ? Icons.favorite : Icons.favorite_border, size: 13, color: VC.red),
                      const SizedBox(width: 3),
                      Text('${piece.likes}', style: sansStyle(11.5, color: VC.muted, weight: FontWeight.w600)),
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
}

class _WaxSealedPromptCard extends StatefulWidget {
  final ValueChanged<String>? onStartWithPrompt;
  const _WaxSealedPromptCard({this.onStartWithPrompt});

  @override
  State<_WaxSealedPromptCard> createState() => _WaxSealedPromptCardState();
}

class _WaxSealedPromptCardState extends State<_WaxSealedPromptCard> {
  bool unsealed = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final prompt = app.currentPrompt;
    return Container(
      decoration: BoxDecoration(
        color: VC.cream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!unsealed) {
              TactileAudio.playPaperTurn();
              setState(() => unsealed = true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              crossFadeState: unsealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: VC.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: VC.red.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFB52B1D), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'M',
                      style: serifStyle(17, color: Colors.white, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY QUIET PROMPT', style: labelStyle(color: VC.muted)),
                        const SizedBox(height: 2),
                        Text(
                          'Wax-sealed for the quiet hours · Tap to unseal',
                          style: serifStyle(14, style: FontStyle.italic, color: VC.ink),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_open_outlined, size: 16, color: VC.muted),
                ],
              ),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: VC.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TODAY’S PROMPT',
                          style: sansStyle(10, color: VC.red, weight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Draw another prompt',
                        icon: const Icon(Icons.refresh, size: 16, color: VC.muted),
                        onPressed: () {
                          TactileAudio.playQuillScratch();
                          app.nextPrompt();
                        },
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Seal envelope',
                        icon: const Icon(Icons.close, size: 16, color: VC.muted),
                        onPressed: () {
                          TactileAudio.playPaperTurn();
                          setState(() => unsealed = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '“$prompt”',
                    style: serifStyle(17.5, style: FontStyle.italic, height: 1.25),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: VC.red,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => widget.onStartWithPrompt?.call(prompt),
                        icon: const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                        label: Text(
                          'Write with this prompt',
                          style: sansStyle(12, color: Colors.white, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriftingBottlePill extends StatelessWidget {
  final VoidCallback onTap;
  const _DriftingBottlePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.waves, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Lake letters · ${app.bottles.length} ashore',
                style: sansStyle(12, color: Colors.white, weight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

void showDriftingBottlesModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: VC.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (c) => const _DriftingBottlesModalContent(),
  );
}

class _DriftingBottlesModalContent extends StatefulWidget {
  const _DriftingBottlesModalContent();

  @override
  State<_DriftingBottlesModalContent> createState() => _DriftingBottlesModalContentState();
}

class _DriftingBottlesModalContentState extends State<_DriftingBottlesModalContent> {
  DriftingBottle? _uncorked;
  bool _isCasting = false;
  final _textCtrl = TextEditingController();
  String _selectedLocation = 'North Pier';

  static const locations = ['North Pier', 'Pine Shallows', 'Lighthouse Beach', 'Island Cove'];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 20, 22, bottomInset + 20),
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
                  const Icon(Icons.waves, size: 20, color: VC.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Drifting Lake Bottles', style: serifStyle(24)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Anonymous notes left to wander the water. Uncork one to read, or cast your own.',
                style: sansStyle(12.5, color: VC.muted),
              ),
              const SizedBox(height: 18),

              // Uncorked bottle section
              if (_uncorked != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VC.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VC.paperDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: VC.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'FOUND AT ${_uncorked!.location.toUpperCase()}',
                                style: sansStyle(9.5, color: VC.blue, weight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Uncorked ${_uncorked!.uncorkCount}×',
                            style: sansStyle(10.5, color: VC.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '“${_uncorked!.text}”',
                        style: serifStyle(18, style: FontStyle.italic, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '— ${_uncorked!.author}',
                        style: sansStyle(11.5, color: VC.muted, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Actions: Uncork & Cast toggle
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: VC.blue),
                      ),
                      onPressed: () {
                        TactileAudio.playWaterRipple();
                        final b = app.uncorkRandomBottle();
                        setState(() => _uncorked = b);
                      },
                      icon: const Icon(Icons.wine_bar_outlined, size: 16, color: VC.blue),
                      label: Text(
                        _uncorked == null ? 'Uncork a bottle' : 'Uncork another',
                        style: sansStyle(12.5, color: VC.blue, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: VC.navy,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => setState(() => _isCasting = !_isCasting),
                      icon: Icon(_isCasting ? Icons.close : Icons.send_outlined, size: 15, color: Colors.white),
                      label: Text(
                        _isCasting ? 'Cancel' : 'Cast a bottle',
                        style: sansStyle(12.5, color: Colors.white, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),

              // Casting form
              if (_isCasting) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WRITE A QUIET SENTENCE', style: labelStyle()),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textCtrl,
                        maxLength: 140,
                        maxLines: 3,
                        style: serifStyle(16),
                        decoration: InputDecoration(
                          hintText: 'A sentence for someone walking the shore tonight…',
                          filled: true,
                          fillColor: VC.paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('WHERE TO CAST IT', style: labelStyle()),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final loc in locations)
                            ChoiceChip(
                              label: Text(loc, style: sansStyle(11, weight: FontWeight.w600)),
                              selected: _selectedLocation == loc,
                              onSelected: (_) => setState(() => _selectedLocation = loc),
                              selectedColor: VC.blue.withValues(alpha: 0.2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: VC.red,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.all(14),
                          ),
                          onPressed: () {
                            final text = _textCtrl.text.trim();
                            if (text.isNotEmpty) {
                              TactileAudio.playWaterRipple();
                              app.castBottle(text, location: _selectedLocation);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bottle cast into the lake.')),
                              );
                            }
                          },
                          child: Text(
                            'Cast into the lake',
                            style: sansStyle(13.5, color: Colors.white, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
