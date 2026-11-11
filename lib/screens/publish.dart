import 'package:flutter/material.dart';
import '../art.dart';
import '../state.dart';
import '../theme.dart';
import 'shell.dart';

class PublishScreen extends StatefulWidget {
  final Piece piece;
  const PublishScreen({super.key, required this.piece});
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  static const coverOrder = [2, 0, 1, 3, 4, 5, 6, 7]; // 4 classic + 4 extended literary covers
  late int cover = widget.piece.cover;
  late Audience audience = widget.piece.audience;
  late bool notes = widget.piece.allowNotes;
  late bool hold = widget.piece.allowHold;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      backgroundColor: VC.blue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CircleBtn(icon: Icons.chevron_left, onTap: () => Navigator.pop(context)),
                  ),
                  const SizedBox(height: 18),
                  Text('Ready to share?', style: serifStyle(36, color: Colors.white)),
                  const SizedBox(height: 22),
                  Text('CHOOSE A COVER', style: labelStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final variant in coverOrder)
                          GestureDetector(
                            onTap: () {
                              TactileAudio.playQuillScratch();
                              setState(() => cover = variant);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(3),
                              width: 74,
                              height: 88,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(60),
                                  bottom: Radius.circular(10),
                                ),
                                border: Border.all(
                                  color: variant == cover ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ArchArt(variant: variant),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('WHO CAN SEE IT', style: labelStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  PillTabs(
                    labels: const ['Exhibit', 'Followers', 'Only me'],
                    index: audience.index,
                    onBlue: true,
                    onChanged: (i) => setState(() => audience = Audience.values[i]),
                  ),
                  const SizedBox(height: 16),
                  _toggle(
                    'Let readers leave notes',
                    'Short replies, never public comments',
                    notes,
                    (v) => setState(() => notes = v),
                  ),
                  _toggle(
                    'Let others hold lines',
                    'Readers can save a line they love',
                    hold,
                    (v) => setState(() => hold = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: VC.red,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      TactileAudio.playPaperTurn();
                      widget.piece
                        ..cover = cover
                        ..audience = audience
                        ..allowNotes = notes
                        ..allowHold = hold;
                      app.publish(widget.piece);
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            audience == Audience.onlyMe ? 'Saved privately to your Shelf' : 'Hung in the Exhibit',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      audience == Audience.onlyMe ? 'Keep on my Shelf' : 'Publish to the Exhibit',
                      style: sansStyle(14.5, color: Colors.white, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'You can edit or unpublish anytime from your Shelf.',
                      style: sansStyle(11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            VersoNavBar(
              index: 1,
              onTap: (i) {
                app.setTab(i);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String t, String s, bool v, ValueChanged<bool> f) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: sansStyle(14, color: Colors.white, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(s, style: sansStyle(11, color: Colors.white60)),
                ],
              ),
            ),
            Switch(
              value: v,
              onChanged: f,
              activeTrackColor: VC.red,
              activeThumbColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              inactiveThumbColor: Colors.white,
              trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
          ],
        ),
      );
}
