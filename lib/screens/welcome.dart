import 'package:flutter/material.dart';
import '../art.dart';
import '../theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ctrl = PageController();
  int page = 0;

  static const pages = [
    (
      'Publish your pages.',
      'Wander other people’s.',
      'Share poems and journals in a quiet exhibit, and read what others left on the water.',
    ),
    (
      'Write on paper',
      'that never runs out.',
      'A page that feels like paper. Drafts save themselves while you think.',
    ),
    (
      'Keep a shelf',
      'of everything you made.',
      'Published pieces and drafts, bound like books, all in one place.',
    ),
  ];

  void next() {
    if (page < pages.length - 1) {
      ctrl.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: VC.blue,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: ctrl,
              builder: (_, _) {
                final p = ctrl.hasClients && ctrl.position.haveDimensions ? (ctrl.page ?? 0.0) : 0.0;
                return ClipPath(
                  clipper: TornSideClipper(0.62 + 0.03 * (p % 1)),
                  child: Container(color: VC.paper),
                );
              },
            ),
          ),
          // Complete split-world scene (boat, open book, cottage, red tree, water reflection)
          Positioned.fill(child: CustomPaint(painter: WelcomeScenePainter(page))),
          // Bottom torn card with copy
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: TornTopClipper(seed: 11, depth: 12),
              child: Container(
                color: VC.cream,
                width: double.infinity,
                height: size.height * 0.37,
                padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: ctrl,
                        itemCount: pages.length,
                        onPageChanged: (i) => setState(() => page = i),
                        itemBuilder: (_, i) {
                          final (a, b, c) = pages[i];
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a, style: serifStyle(29, height: 1.15)),
                                Text(b, style: serifStyle(29, style: FontStyle.italic, height: 1.15)),
                                const SizedBox(height: 12),
                                Text(c, style: sansStyle(13.5, color: VC.muted, height: 1.45)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            width: i == page ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == page ? VC.red : VC.muted.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/auth'),
                          child: Text('Sign in', style: sansStyle(13, color: VC.ink, weight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: next,
                          child: Container(
                            width: 116,
                            height: 48,
                            decoration: BoxDecoration(
                              color: VC.red,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              page == pages.length - 1 ? 'Enter' : 'Next',
                              style: sansStyle(14, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  ),
                  child: Text('Skip', style: sansStyle(13, color: Colors.white, weight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
