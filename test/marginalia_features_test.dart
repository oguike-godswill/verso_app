import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verso/state.dart';
import 'package:verso/screens/exhibit.dart';
import 'package:verso/screens/poem.dart';

void main() {
  test('Tactile Audio synthesizes valid PCM WAV buffers for paper rustle and water ripple', () {
    final rustle = TactileAudio.synthesizePaperRustle();
    expect(rustle, isNotEmpty);
    expect(rustle.length, greaterThan(1000));
    // Check RIFF header: 'R', 'I', 'F', 'F'
    expect(rustle[0], 0x52);
    expect(rustle[1], 0x49);
    expect(rustle[2], 0x46);
    expect(rustle[3], 0x46);

    final ripple = TactileAudio.synthesizeWaterRipple();
    expect(ripple, isNotEmpty);
    expect(ripple.length, greaterThan(1000));
    expect(ripple[0], 0x52);
    expect(ripple[1], 0x49);
    expect(ripple[2], 0x46);
    expect(ripple[3], 0x46);
  });

  test('AppState supports midnight lamp, prompt cycling, and drifting bottles', () {
    final app = AppState(enableDiskPersistence: false);

    // 1. Midnight Reading Lamp
    expect(app.midnightLamp, isFalse);
    app.toggleMidnightLamp();
    expect(app.midnightLamp, isTrue);
    app.toggleMidnightLamp();
    expect(app.midnightLamp, isFalse);

    // 2. Daily Quiet Writing Prompt
    final firstPrompt = app.currentPrompt;
    expect(firstPrompt, isNotEmpty);
    app.nextPrompt();
    final secondPrompt = app.currentPrompt;
    expect(secondPrompt, isNot(equals(firstPrompt)));

    // 3. Drifting Lake Bottles
    final initialBottleCount = app.bottles.length;
    expect(initialBottleCount, greaterThanOrEqualTo(4));
    app.castBottle('A quiet letter to the north tide.', location: 'Lighthouse Beach');
    expect(app.bottles.length, equals(initialBottleCount + 1));
    expect(app.bottles.first.text, equals('A quiet letter to the north tide.'));
    expect(app.bottles.first.location, equals('Lighthouse Beach'));

    final uncorked = app.uncorkRandomBottle();
    expect(uncorked, isNotNull);
    expect(uncorked!.uncorkCount, greaterThanOrEqualTo(1));
  });

  testWidgets('Daily Prompt unseals on Exhibit and triggers Write draft', (tester) async {
    final app = AppState(enableDiskPersistence: false);

    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? promptReceived;
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          home: Scaffold(
            body: ExhibitScreen(
              onStartWithPrompt: (p) => promptReceived = p,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify wax seal card
    expect(find.text('DAILY QUIET PROMPT'), findsOneWidget);
    expect(find.text('M'), findsOneWidget); // Monogram

    // Tap to unseal
    await tester.tap(find.text('DAILY QUIET PROMPT'));
    await tester.pumpAndSettle();

    expect(find.text('TODAY’S PROMPT'), findsOneWidget);
    expect(find.text('Write with this prompt'), findsOneWidget);

    // Tap write button
    await tester.tap(find.text('Write with this prompt'));
    await tester.pumpAndSettle();

    expect(promptReceived, equals(app.currentPrompt));
  });

  testWidgets('Drifting Lake Bottles modal opens and displays letters', (tester) async {
    final app = AppState(enableDiskPersistence: false);

    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppScope(
        state: app,
        child: const MaterialApp(
          home: Scaffold(body: ExhibitScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Drifting Bottles button
    final bottlePill = find.textContaining('Lake letters');
    expect(bottlePill, findsOneWidget);
    await tester.tap(bottlePill);
    await tester.pumpAndSettle();

    expect(find.text('Drifting Lake Bottles'), findsOneWidget);
    expect(find.text('Uncork a bottle'), findsOneWidget);
    expect(find.text('Cast a bottle'), findsOneWidget);

    // Tap uncork
    await tester.tap(find.text('Uncork a bottle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('FOUND AT'), findsOneWidget);
  });

  testWidgets('Printable Chapbook 8-page mini-zine sheet modal opens from PoemScreen', (tester) async {
    final app = AppState(enableDiskPersistence: false);
    final piece = app.allPieces.first;

    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          home: PoemScreen(piece: piece),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap print button in top bar
    final printBtn = find.byIcon(Icons.print_outlined);
    expect(printBtn, findsOneWidget);
    await tester.tap(printBtn);
    await tester.pumpAndSettle();

    expect(find.text('8-Page Pocket Chapbook'), findsOneWidget);
    expect(find.text('Sheet Fold (2×4)'), findsOneWidget);
    expect(find.text('CUT CENTER SLIT'), findsOneWidget);

    // Switch to booklet flip view
    await tester.tap(find.text('Flip Booklet (1–8)'));
    await tester.pumpAndSettle();

    expect(find.text('PAGE 1 OF 8'), findsOneWidget);
    expect(find.text('Copy zine text'), findsOneWidget);
  });
}
