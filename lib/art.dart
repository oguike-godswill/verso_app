import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

const int kArchVariantCount = 8;

/// Arch-shaped illustrated cover. 8 variants (4 classic @queeneo.ui covers + 4 extended literary scenes).
class ArchArt extends StatelessWidget {
  final int variant;
  final double radius;
  final bool? arch;
  final double bottomCornerRadius;
  final bool? showInnerFrame;

  const ArchArt({
    super.key,
    required this.variant,
    this.radius = 999,
    this.arch = true,
    this.bottomCornerRadius = 10,
    this.showInnerFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArch = arch != false;
    final hasInnerFrame = showInnerFrame == true;
    return ClipPath(
      clipper: isArch ? _ArchClipper(bottomRadius: bottomCornerRadius) : null,
      child: CustomPaint(
        painter: _ScenePainter(variant % kArchVariantCount, showInnerFrame: hasInnerFrame),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ArchClipper extends CustomClipper<Path> {
  final double bottomRadius;
  _ArchClipper({this.bottomRadius = 10});

  @override
  Path getClip(Size s) {
    final r = s.width / 2;
    final br = min(bottomRadius, s.width * 0.15);
    final topR = min(r, s.height - br);
    return Path()
      ..moveTo(0, s.height - br)
      ..lineTo(0, topR)
      ..arcToPoint(Offset(s.width, topR), radius: Radius.circular(r))
      ..lineTo(s.width, s.height - br)
      ..quadraticBezierTo(s.width, s.height, s.width - br, s.height)
      ..lineTo(br, s.height)
      ..quadraticBezierTo(0, s.height, 0, s.height - br)
      ..close();
  }

  @override
  bool shouldReclip(_ArchClipper old) => old.bottomRadius != bottomRadius;
}

class _ScenePainter extends CustomPainter {
  final int v;
  final bool showInnerFrame;
  _ScenePainter(this.v, {this.showInnerFrame = false});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final p = Paint()..isAntiAlias = true;

    switch (v) {
      case 0:
        // Variant 0 ("The Lake"): Deep cobalt sky, cream moon top-right, white cottage with dark gable + doorway,
        // organic red tree, deep navy lake with reflection and ripples.
        final horizon = h * 0.62;
        c.drawRect(Offset.zero & s, p..color = VC.blue);

        // Cream full moon
        c.drawCircle(Offset(w * 0.72, h * 0.27), w * 0.115, p..color = VC.cream);

        // Deep water
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.blueDeep);

        // Red tree reflection in water
        c.drawOval(
          Rect.fromCenter(center: Offset(w * 0.64, horizon + h * 0.08), width: w * 0.18, height: h * 0.045),
          p..color = VC.red.withValues(alpha: 0.28),
        );

        // White cottage body
        final houseLeft = w * 0.24;
        final houseW = w * 0.26;
        final houseH = h * 0.145;
        final houseTop = horizon - houseH;
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(houseLeft, houseTop, houseW, houseH), const Radius.circular(1.5)),
          p..color = VC.cream,
        );

        // Navy pitched roof
        final roof = Path()
          ..moveTo(houseLeft - w * 0.02, houseTop)
          ..lineTo(houseLeft + houseW * 0.5, houseTop - h * 0.075)
          ..lineTo(houseLeft + houseW + w * 0.02, houseTop)
          ..close();
        c.drawPath(roof, p..color = VC.navy);

        // Arched doorway in cottage
        final doorW = houseW * 0.22;
        final doorH = houseH * 0.48;
        final doorLeft = houseLeft + houseW * 0.56;
        c.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(doorLeft, horizon - doorH, doorW, doorH),
            topLeft: Radius.circular(doorW),
            topRight: Radius.circular(doorW),
          ),
          p..color = VC.navy,
        );

        // Red tree trunk + organic layered canopy
        c.drawRect(Rect.fromLTWH(w * 0.625, horizon - h * 0.12, w * 0.024, h * 0.12), p..color = VC.navy);
        _drawOrganicCanopy(c, Offset(w * 0.637, horizon - h * 0.155), w * 0.24, h * 0.14, VC.red);

        // Water ripples
        _ripples(c, w, horizon, h, Colors.white.withValues(alpha: 0.28));
        break;

      case 1:
        // Variant 1 ("Small boats learn quiet"): Warm cream sky, large vermilion sun, tiny rower silhouette on horizon,
        // rich cobalt sea with fine cream ripples.
        final horizon = h * 0.64;
        c.drawRect(Offset.zero & s, p..color = VC.cream);

        // Soft paper grain arcs in sky
        c.drawCircle(Offset(w * 0.5, horizon - h * 0.22), w * 0.175, p..color = VC.red);

        // Tiny boat + figure on the water
        final boatY = horizon - h * 0.015;
        final boat = Path()
          ..moveTo(w * 0.43, boatY)
          ..lineTo(w * 0.57, boatY)
          ..lineTo(w * 0.54, boatY + h * 0.025)
          ..lineTo(w * 0.46, boatY + h * 0.025)
          ..close();
        c.drawPath(boat, p..color = VC.navy);
        c.drawCircle(Offset(w * 0.495, boatY - h * 0.028), w * 0.022, p..color = VC.navy);

        // Cobalt sea
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.blue);

        // Sun reflection shimmer on water
        for (var i = 0; i < 3; i++) {
          final ry = horizon + h * (0.06 + i * 0.065);
          final rw = w * (0.26 - i * 0.05);
          c.drawLine(
            Offset(w * 0.5 - rw / 2, ry),
            Offset(w * 0.5 + rw / 2, ry),
            Paint()
              ..color = VC.cream.withValues(alpha: 0.55)
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round,
          );
        }
        _ripples(c, w, horizon, h, Colors.white.withValues(alpha: 0.25));
        break;

      case 2:
        // Variant 2 ("Your name, written on water"): Warm cream sky, cobalt rolling hill,
        // organic red tree at the crest.
        final hillTop = h * 0.60;
        c.drawRect(Offset.zero & s, p..color = VC.cream);

        // Subtle pale sun in upper-left sky
        c.drawCircle(Offset(w * 0.24, h * 0.28), w * 0.06, p..color = Colors.white.withValues(alpha: 0.45));

        // Tree trunk
        c.drawRect(Rect.fromLTWH(w * 0.485, hillTop - h * 0.16, w * 0.028, h * 0.18), p..color = VC.navy);

        // Organic red canopy
        _drawOrganicCanopy(c, Offset(w * 0.5, hillTop - h * 0.21), w * 0.38, h * 0.21, VC.red);

        // Cobalt curved hill
        final hill = Path()
          ..moveTo(0, h * 0.72)
          ..quadraticBezierTo(w * 0.5, hillTop - h * 0.04, w, h * 0.72)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        c.drawPath(hill, p..color = VC.blue);

        // Deep navy base shadow
        c.drawRect(Rect.fromLTWH(0, h * 0.88, w, h * 0.12), p..color = VC.blueDeep.withValues(alpha: 0.45));
        break;

      case 3:
        // Variant 3 ("Salt, then silence"): Vermilion red sky, large cream sun above dark navy sea,
        // crimson horizon glow and reflection lines.
        final horizon = h * 0.68;
        c.drawRect(Offset.zero & s, p..color = VC.red);

        // Cream sun
        c.drawCircle(Offset(w * 0.5, horizon - h * 0.18), w * 0.175, p..color = VC.cream);

        // Deep navy sea
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.navy);

        // Red reflection lines on navy sea
        final lp = Paint()
          ..color = VC.red.withValues(alpha: 0.8)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 1; i <= 3; i++) {
          final y = horizon + i * h * 0.075;
          final span = w * (0.34 - i * 0.05);
          c.drawLine(Offset(w * 0.5 - span, y), Offset(w * 0.5 + span, y), lp);
        }
        break;

      case 4:
        // Variant 4 ("Midnight Lighthouse"): Deep navy sky, crescent moon, white lighthouse on rocky headland,
        // warm golden-cream light beam across dark sea.
        final horizon = h * 0.66;
        c.drawRect(Offset.zero & s, p..color = VC.navy);

        // Crescent moon
        c.drawCircle(Offset(w * 0.28, h * 0.27), w * 0.095, p..color = VC.cream);
        c.drawCircle(Offset(w * 0.31, h * 0.25), w * 0.085, p..color = VC.navy);

        // Warm light beam cone from lighthouse
        final beam = Path()
          ..moveTo(w * 0.66, horizon - h * 0.22)
          ..lineTo(w * 0.05, horizon - h * 0.32)
          ..lineTo(w * 0.05, horizon - h * 0.10)
          ..close();
        c.drawPath(beam, p..color = VC.cream.withValues(alpha: 0.18));

        // Lighthouse tower + red lantern cap
        final tower = Path()
          ..moveTo(w * 0.62, horizon)
          ..lineTo(w * 0.64, horizon - h * 0.22)
          ..lineTo(w * 0.70, horizon - h * 0.22)
          ..lineTo(w * 0.72, horizon)
          ..close();
        c.drawPath(tower, p..color = VC.cream);
        c.drawRect(Rect.fromLTWH(w * 0.635, horizon - h * 0.255, w * 0.07, h * 0.035), p..color = VC.red);

        // Cobalt sea + ripples
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.blueDeep);
        _ripples(c, w, horizon, h, VC.cream.withValues(alpha: 0.3));
        break;

      case 5:
        // Variant 5 ("Distant Peaks"): Warm paper sky, crimson sun behind layered cobalt & navy mountain peaks,
        // mirror lake below.
        final horizon = h * 0.65;
        c.drawRect(Offset.zero & s, p..color = VC.paper);
        c.drawCircle(Offset(w * 0.52, horizon - h * 0.22), w * 0.16, p..color = VC.red);

        // Back cobalt mountain
        final m1 = Path()
          ..moveTo(w * 0.05, horizon)
          ..lineTo(w * 0.38, horizon - h * 0.24)
          ..lineTo(w * 0.72, horizon)
          ..close();
        c.drawPath(m1, p..color = VC.blue);

        // Front navy peak
        final m2 = Path()
          ..moveTo(w * 0.32, horizon)
          ..lineTo(w * 0.66, horizon - h * 0.20)
          ..lineTo(w * 0.96, horizon)
          ..close();
        c.drawPath(m2, p..color = VC.navy);

        // Lake
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.blueDeep);
        _ripples(c, w, horizon, h, Colors.white.withValues(alpha: 0.28));
        break;

      case 6:
        // Variant 6 ("Two Cypresses & Arch"): Cobalt sky, warm cream archway ruin on a red-earth terrace,
        // dark navy cypress silhouettes.
        final horizon = h * 0.68;
        c.drawRect(Offset.zero & s, p..color = VC.blue);
        c.drawCircle(Offset(w * 0.5, h * 0.36), w * 0.22, p..color = VC.cream);
        c.drawCircle(Offset(w * 0.5, h * 0.40), w * 0.13, p..color = VC.blue);

        // Twin cypress trees
        c.drawOval(Rect.fromCenter(center: Offset(w * 0.28, horizon - h * 0.12), width: w * 0.09, height: h * 0.26), p..color = VC.navy);
        c.drawOval(Rect.fromCenter(center: Offset(w * 0.72, horizon - h * 0.10), width: w * 0.08, height: h * 0.22), p..color = VC.navy);

        // Red terrace base
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.red);
        break;

      default:
        // Variant 7 ("Paper Sail"): Cream sky, cobalt sea, tall geometric vermilion & navy sailboat,
        // two small birds in flight.
        final horizon = h * 0.64;
        c.drawRect(Offset.zero & s, p..color = VC.cream);
        c.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), p..color = VC.blue);

        // Main red sail
        final sail1 = Path()
          ..moveTo(w * 0.48, horizon - h * 0.04)
          ..lineTo(w * 0.48, horizon - h * 0.32)
          ..lineTo(w * 0.68, horizon - h * 0.04)
          ..close();
        c.drawPath(sail1, p..color = VC.red);

        // Fore navy jib sail
        final sail2 = Path()
          ..moveTo(w * 0.45, horizon - h * 0.04)
          ..lineTo(w * 0.45, horizon - h * 0.24)
          ..lineTo(w * 0.32, horizon - h * 0.04)
          ..close();
        c.drawPath(sail2, p..color = VC.navy);

        // Hull
        final hull = Path()
          ..moveTo(w * 0.30, horizon - h * 0.02)
          ..lineTo(w * 0.70, horizon - h * 0.02)
          ..lineTo(w * 0.64, horizon + h * 0.03)
          ..lineTo(w * 0.36, horizon + h * 0.03)
          ..close();
        c.drawPath(hull, p..color = VC.navy);
        _ripples(c, w, horizon, h, Colors.white.withValues(alpha: 0.3));
    }

    if (showInnerFrame) {
      final framePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      final inset = w * 0.05;
      final r = (w - inset * 2) / 2;
      final framePath = Path()
        ..moveTo(inset, h)
        ..lineTo(inset, inset + r)
        ..arcToPoint(Offset(w - inset, inset + r), radius: Radius.circular(r))
        ..lineTo(w - inset, h);
      c.drawPath(framePath, framePaint);
    }
  }

  void _drawOrganicCanopy(Canvas c, Offset center, double width, double height, Color color) {
    final p = Paint()
      ..color = color
      ..isAntiAlias = true;
    c.drawOval(Rect.fromCenter(center: center, width: width, height: height), p);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - width * 0.18, center.dy + height * 0.08),
        width: width * 0.65,
        height: height * 0.75,
      ),
      p,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + width * 0.18, center.dy + height * 0.06),
        width: width * 0.65,
        height: height * 0.78,
      ),
      p,
    );
  }

  void _ripples(Canvas c, double w, double horizon, double h, Color color) {
    final lp = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 4; i++) {
      final y = horizon + i * h * 0.068;
      final inset = w * 0.14 + (i.isEven ? 12.0 : 4.0);
      c.drawLine(Offset(inset, y), Offset(w - inset, y), lp);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter o) => o.v != v || o.showInnerFrame != showInnerFrame;
}

/// Torn-paper top edge clipper.
class TornTopClipper extends CustomClipper<Path> {
  final int seed;
  final double depth;
  TornTopClipper({this.seed = 3, this.depth = 10});

  @override
  Path getClip(Size s) {
    final r = Random(seed);
    final path = Path()..moveTo(0, depth);
    double x = 0;
    while (x < s.width) {
      x += 3.5 + r.nextDouble() * 6.5;
      path.lineTo(min(x, s.width), r.nextDouble() * depth);
    }
    path
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(TornTopClipper old) => old.seed != seed || old.depth != depth;
}

/// Torn-paper vertical edge (used in the Welcome & Auth hero).
class TornSideClipper extends CustomClipper<Path> {
  final double fraction;
  TornSideClipper(this.fraction);

  @override
  Path getClip(Size s) {
    final r = Random(7);
    final base = s.width * fraction;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(base, 0);
    double y = 0;
    while (y < s.height) {
      y += 4.5 + r.nextDouble() * 8;
      path.lineTo(base + (r.nextDouble() - 0.5) * 14, min(y, s.height));
    }
    path
      ..lineTo(0, s.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(TornSideClipper o) => o.fraction != fraction;
}

/// Full Welcome / Auth split-world illustration (paper left with boat + open book, cobalt right with cottage + red tree + water reflections).
class WelcomeScenePainter extends CustomPainter {
  final int page;
  WelcomeScenePainter(this.page);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final horizon = h * 0.50;
    final p = Paint()..isAntiAlias = true;

    // --- RIGHT SIDE (Cobalt World) ---
    // Deep water on right half below horizon
    c.drawRect(Rect.fromLTWH(w * 0.55, horizon, w * 0.45, h * 0.25), p..color = VC.blueDeep);

    // Subtle vertical light streaks in upper blue sky
    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w * 0.80, h * 0.14), Offset(w * 0.80, h * 0.30), streakPaint);
    c.drawLine(Offset(w * 0.90, h * 0.10), Offset(w * 0.90, h * 0.26), streakPaint);

    // Cottage on the shoreline
    final houseLeft = w * 0.72;
    final houseW = w * 0.18;
    final houseH = h * 0.065;
    final houseTop = horizon - houseH;

    // House reflection in deep water
    c.drawRect(
      Rect.fromLTWH(houseLeft, horizon + 2, houseW, houseH * 0.55),
      p..color = VC.cream.withValues(alpha: 0.14),
    );
    // Red tree reflection in deep water
    c.drawOval(
      Rect.fromCenter(center: Offset(w * 0.92, horizon + h * 0.038), width: w * 0.15, height: h * 0.055),
      p..color = VC.red.withValues(alpha: 0.28),
    );

    // Cottage body
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(houseLeft, houseTop, houseW, houseH), const Radius.circular(1.5)),
      p..color = VC.cream,
    );
    // Cottage roof
    final roof = Path()
      ..moveTo(houseLeft - 4, houseTop)
      ..lineTo(houseLeft + houseW * 0.5, houseTop - h * 0.028)
      ..lineTo(houseLeft + houseW + 4, houseTop)
      ..close();
    c.drawPath(roof, p..color = VC.navy);

    // Cottage arched door & small window
    final doorW = houseW * 0.20;
    final doorH = houseH * 0.52;
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(houseLeft + houseW * 0.44, horizon - doorH, doorW, doorH),
        topLeft: Radius.circular(doorW),
        topRight: Radius.circular(doorW),
      ),
      p..color = VC.navy,
    );
    c.drawRect(
      Rect.fromLTWH(houseLeft + houseW * 0.76, houseTop + houseH * 0.25, houseW * 0.11, houseH * 0.22),
      p..color = VC.navy,
    );

    // Red tree on right edge
    c.drawRect(Rect.fromLTWH(w * 0.915, horizon - h * 0.055, w * 0.014, h * 0.055), p..color = VC.navy);
    final treeCanopy = Paint()
      ..color = VC.red
      ..isAntiAlias = true;
    c.drawOval(
      Rect.fromCenter(center: Offset(w * 0.925, horizon - h * 0.068), width: w * 0.16, height: h * 0.055),
      treeCanopy,
    );

    // Horizontal water lines on the blue side
    final blueWaterLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var i = 1; i <= 5; i++) {
      final wy = horizon + i * h * 0.022;
      c.drawLine(Offset(w * 0.65, wy), Offset(w * 0.96, wy), blueWaterLine);
    }

    // --- LEFT SIDE (Warm Paper World) ---
    // Fine horizontal water lines on paper
    final paperLine = Paint()
      ..color = VC.navy.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final ly = horizon + h * 0.028 + i * 14;
      c.drawLine(Offset(w * 0.08 + (i.isOdd ? 12 : 0), ly), Offset(w * 0.48 - (i * 8), ly), paperLine);
    }

    // Small boat with rower silhouette on the horizon line
    final boatX = w * 0.22 + page * 6.0;
    final boatY = horizon;
    final boatHull = Path()
      ..moveTo(boatX - w * 0.055, boatY)
      ..lineTo(boatX + w * 0.055, boatY)
      ..lineTo(boatX + w * 0.036, boatY + 6.5)
      ..lineTo(boatX - w * 0.036, boatY + 6.5)
      ..close();
    c.drawPath(boatHull, p..color = VC.navy);
    // Rower torso + head
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(boatX - 2.5, boatY - 8, 5, 8), const Radius.circular(2)),
      p..color = VC.navy,
    );
    c.drawCircle(Offset(boatX, boatY - 11), 2.6, p..color = VC.navy);

    // Open book with curved pages + soft shadow at bottom of illustration
    final bx = w * 0.22;
    final by = h * 0.565;
    final bw = w * 0.30;
    final bh = h * 0.055;

    // Soft shadow under book
    c.drawOval(
      Rect.fromCenter(center: Offset(bx + bw * 0.5, by + bh + 7), width: bw * 1.05, height: 10),
      p..color = VC.navy.withValues(alpha: 0.10),
    );

    final leftPage = Path()
      ..moveTo(bx, by)
      ..quadraticBezierTo(bx + bw * 0.25, by - 7, bx + bw * 0.5, by + 2)
      ..lineTo(bx + bw * 0.5, by + bh + 2)
      ..quadraticBezierTo(bx + bw * 0.25, by + bh - 5, bx, by + bh)
      ..close();

    final rightPage = Path()
      ..moveTo(bx + bw * 0.5, by + 2)
      ..quadraticBezierTo(bx + bw * 0.75, by - 7, bx + bw, by)
      ..lineTo(bx + bw, by + bh)
      ..quadraticBezierTo(bx + bw * 0.75, by + bh - 5, bx + bw * 0.5, by + bh + 2)
      ..close();

    final pageFill = Paint()..color = VC.cream;
    final pageStroke = Paint()
      ..color = VC.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    c.drawPath(leftPage, pageFill);
    c.drawPath(rightPage, pageFill);
    c.drawPath(leftPage, pageStroke);
    c.drawPath(rightPage, pageStroke);

    // Ruled text lines inside the open book
    final textLinePaint = Paint()
      ..color = VC.navy.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (var i = 1; i <= 4; i++) {
      final ty = by + i * (bh / 5.2);
      final lLine = Path()
        ..moveTo(bx + 7, ty)
        ..quadraticBezierTo(bx + bw * 0.25, ty - 4, bx + bw * 0.5 - 6, ty + 1);
      final rLine = Path()
        ..moveTo(bx + bw * 0.5 + 6, ty + 1)
        ..quadraticBezierTo(bx + bw * 0.75, ty - 4, bx + bw - 7, ty);
      c.drawPath(lLine, textLinePaint);
      c.drawPath(rLine, textLinePaint);
    }
  }

  @override
  bool shouldRepaint(WelcomeScenePainter o) => o.page != page;
}
