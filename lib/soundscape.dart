import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

enum Soundscape { off, rainOnWater, distantOars, nightHarbor }

extension SoundscapeMeta on Soundscape {
  String get label => switch (this) {
        Soundscape.off => 'Silence',
        Soundscape.rainOnWater => 'Rain on water',
        Soundscape.distantOars => 'Distant oars',
        Soundscape.nightHarbor => 'Night harbor',
      };

  IconData get icon => switch (this) {
        Soundscape.off => Icons.volume_off_outlined,
        Soundscape.rainOnWater => Icons.water_drop_outlined,
        Soundscape.distantOars => Icons.rowing_outlined,
        Soundscape.nightHarbor => Icons.nights_stay_outlined,
      };
}

enum PaperStock { warmCream, fadedParchment, midnightHarbor }

extension PaperStockMeta on PaperStock {
  String get label => switch (this) {
        PaperStock.warmCream => 'Cream',
        PaperStock.fadedParchment => 'Parchment',
        PaperStock.midnightHarbor => 'Midnight',
      };

  Color get bg => switch (this) {
        PaperStock.warmCream => VC.cream,
        PaperStock.fadedParchment => const Color(0xFFE9DFC7),
        PaperStock.midnightHarbor => const Color(0xFF101D3B),
      };

  Color get fg => switch (this) {
        PaperStock.midnightHarbor => const Color(0xFFF3EDE0),
        _ => VC.ink,
      };

  Color get rule => switch (this) {
        PaperStock.midnightHarbor => Colors.white.withValues(alpha: 0.12),
        _ => VC.muted.withValues(alpha: 0.16),
      };
}

/// Generates a gentle procedural WAV buffer in memory for ambient writing soundscapes
/// and provides a visual waveform badge for the Write & Poem screens.
class SoundscapeBadge extends StatefulWidget {
  final Soundscape active;
  final ValueChanged<Soundscape> onChanged;
  const SoundscapeBadge({super.key, required this.active, required this.onChanged});

  @override
  State<SoundscapeBadge> createState() => _SoundscapeBadgeState();
}

class _SoundscapeBadgeState extends State<SoundscapeBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cycle() {
    final next = Soundscape.values[(widget.active.index + 1) % Soundscape.values.length];
    if (next != Soundscape.off) {
      synthesizeWave(next);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.active != Soundscape.off;
    return GestureDetector(
      onTap: _cycle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? VC.blue.withValues(alpha: 0.14) : VC.paperDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.active.icon, size: 13, color: on ? VC.blue : VC.muted),
            const SizedBox(width: 5),
            Text(
              widget.active.label,
              style: sansStyle(11, color: on ? VC.blue : VC.muted, weight: FontWeight.w700),
            ),
            if (on) ...[
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) => Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 2,
                        height: 5 + 6 * sin((_ctrl.value * pi) + i * 1.1).abs(),
                        decoration: BoxDecoration(
                          color: VC.blue,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Synthesizes a 2-second 8kHz mono PCM WAV loop in memory for tests/exports.
  static Uint8List synthesizeWave(Soundscape mode) {
    const sampleRate = 8000;
    const seconds = 2;
    const numSamples = sampleRate * seconds;
    final byteData = ByteData(44 + numSamples * 2);
    // RIFF header
    const riff = [0x52, 0x49, 0x46, 0x46];
    const wave = [0x57, 0x41, 0x56, 0x45];
    const fmt = [0x66, 0x6D, 0x74, 0x20];
    const data = [0x64, 0x61, 0x74, 0x61];
    for (var i = 0; i < 4; i++) {
      byteData.setUint8(i, riff[i]);
      byteData.setUint8(8 + i, wave[i]);
      byteData.setUint8(12 + i, fmt[i]);
      byteData.setUint8(36 + i, data[i]);
    }
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint32(40, numSamples * 2, Endian.little);

    final rng = Random(mode.index);
    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = 0.5 - 0.5 * cos(2 * pi * t / seconds);
      final noise = (rng.nextDouble() * 2 - 1) * 0.15;
      final tone = sin(2 * pi * (mode == Soundscape.nightHarbor ? 196 : 261.6) * t) * 0.2;
      final sample = ((noise + tone) * env * 12000).clamp(-32767, 32767).toInt();
      byteData.setInt16(44 + i * 2, sample, Endian.little);
    }
    return byteData.buffer.asUint8List();
  }
}

/// Synthesizes tactile sounds and triggers haptic/sensory feedback for quiet interactions:
/// paper turning, quill writing, and lake bottle uncorking.
class TactileAudio {
  static void playPaperTurn() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void playQuillScratch() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void playWaterRipple() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Synthesizes a soft 200ms paper rustle PCM WAV buffer.
  static Uint8List synthesizePaperRustle() {
    const sampleRate = 8000;
    final numSamples = (sampleRate * 0.22).toInt();
    final byteData = ByteData(44 + numSamples * 2);
    _writeWavHeader(byteData, sampleRate, numSamples);
    final rng = Random(42);
    for (var i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Envelope: quick attack, soft fluttering decay
      final env = (1.0 - t) * sin(pi * t * 2.5).clamp(0.0, 1.0);
      final noise = (rng.nextDouble() * 2 - 1) * 0.45;
      final rustleTone = sin(2 * pi * (320 + rng.nextDouble() * 180) * (i / sampleRate)) * 0.2;
      final sample = ((noise + rustleTone) * env * 9000).clamp(-32767, 32767).toInt();
      byteData.setInt16(44 + i * 2, sample, Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  /// Synthesizes a gentle water ripple splash WAV buffer.
  static Uint8List synthesizeWaterRipple() {
    const sampleRate = 8000;
    final numSamples = (sampleRate * 0.35).toInt();
    final byteData = ByteData(44 + numSamples * 2);
    _writeWavHeader(byteData, sampleRate, numSamples);
    final rng = Random(108);
    for (var i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = sin(pi * t) * (1.0 - t * 0.6);
      final dropletTone = sin(2 * pi * (520 - t * 220) * (i / sampleRate)) * 0.35;
      final waterNoise = (rng.nextDouble() * 2 - 1) * 0.18;
      final sample = ((dropletTone + waterNoise) * env * 11000).clamp(-32767, 32767).toInt();
      byteData.setInt16(44 + i * 2, sample, Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  static void _writeWavHeader(ByteData b, int sampleRate, int numSamples) {
    const riff = [0x52, 0x49, 0x46, 0x46];
    const wave = [0x57, 0x41, 0x56, 0x45];
    const fmt = [0x66, 0x6D, 0x74, 0x20];
    const data = [0x64, 0x61, 0x74, 0x61];
    for (var i = 0; i < 4; i++) {
      b.setUint8(i, riff[i]);
      b.setUint8(8 + i, wave[i]);
      b.setUint8(12 + i, fmt[i]);
      b.setUint8(36 + i, data[i]);
    }
    b.setUint32(4, 36 + numSamples * 2, Endian.little);
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little);
    b.setUint16(22, 1, Endian.little);
    b.setUint32(24, sampleRate, Endian.little);
    b.setUint32(28, sampleRate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    b.setUint32(40, numSamples * 2, Endian.little);
  }
}

/// Animated "Read Aloud" cadence player for PoemScreen — highlights lines sequentially
/// as if the author is reading the poem aloud at a measured cadence.
class ReadAloudPlayer extends StatefulWidget {
  final List<String> lines;
  final ValueChanged<int?> onActiveLineChanged;
  const ReadAloudPlayer({super.key, required this.lines, required this.onActiveLineChanged});

  @override
  State<ReadAloudPlayer> createState() => _ReadAloudPlayerState();
}

class _ReadAloudPlayerState extends State<ReadAloudPlayer> {
  Timer? _timer;
  int? _current;

  bool get isPlaying => _timer != null;

  void _toggle() {
    if (isPlaying) {
      _stop();
    } else {
      if (widget.lines.isEmpty) return;
      setState(() => _current = 0);
      widget.onActiveLineChanged(0);
      _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
        if (!mounted) return;
        final next = (_current ?? 0) + 1;
        if (next >= widget.lines.length) {
          _stop();
        } else {
          setState(() => _current = next);
          widget.onActiveLineChanged(next);
        }
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _current = null);
      widget.onActiveLineChanged(null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPlaying ? VC.red : VC.paper,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.stop_rounded : Icons.graphic_eq_rounded,
              size: 14,
              color: isPlaying ? Colors.white : VC.ink,
            ),
            const SizedBox(width: 5),
            Text(
              isPlaying ? 'Reading line ${(_current ?? 0) + 1}/${widget.lines.length}' : 'Listen',
              style: sansStyle(
                11.5,
                color: isPlaying ? Colors.white : VC.ink,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
