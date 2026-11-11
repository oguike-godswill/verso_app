import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verso/state.dart';
import 'package:verso/screens/poem.dart';
import 'package:verso/screens/exhibit.dart';
import 'package:verso/screens/shell.dart';

void main() {
  testWidgets('PoemScreen renders all content, arch, stanzas, and action bar', (tester) async {
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

    // Verify Title
    expect(find.text('The Lake'), findsOneWidget);
    // Verify Author
    expect(find.text('@ila'), findsOneWidget);
    // Verify Action buttons
    expect(find.text('Leave a note'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);

    // Verify "This week" badge
    expect(find.text('This week'), findsOneWidget);

    // Verify poem line
    expect(find.text('The lake kept my shape'), findsOneWidget);

    // Verify VersoNavBar
    expect(find.byType(VersoNavBar), findsOneWidget);
  });

  testWidgets('PoemScreen renders across multiple screen sizes without overflow', (tester) async {
    final app = AppState(enableDiskPersistence: false);
    final piece = app.allPieces.first;

    final sizes = [
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
      const Size(800, 600),
      const Size(1200, 800),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size * 2.0;
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(
            home: PoemScreen(piece: piece),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PoemScreen), findsOneWidget);
      expect(find.text('The Lake'), findsOneWidget);
      expect(find.text('Leave a note'), findsOneWidget);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Exhibit tap opens PoemScreen and back button returns', (tester) async {
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

    // Tap first ExhibitCard
    final card = find.byType(ExhibitCard).first;
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byType(PoemScreen), findsOneWidget);
    expect(find.text('Leave a note'), findsOneWidget);

    // Tap back button
    final backBtn = find.descendant(of: find.byType(PoemScreen), matching: find.byIcon(Icons.chevron_left));
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.byType(PoemScreen), findsNothing);
    expect(find.byType(ExhibitScreen), findsOneWidget);
  });

  testWidgets('Registration and SignIn async consistency', (tester) async {
    final app = AppState(enableDiskPersistence: false);

    // Invalid email
    final err1 = await app.signUp(
      name: 'Clara',
      handle: '@clara',
      email: 'notanemail',
      password: 'password123',
    );
    expect(err1, isNotNull);

    // Short password
    final err2 = await app.signUp(
      name: 'Clara',
      handle: '@clara',
      email: 'clara@verso.app',
      password: '12',
    );
    expect(err2, isNotNull);

    // Duplicate handle
    final err3 = await app.signUp(
      name: 'Imposter',
      handle: '@ila',
      email: 'imposter@verso.app',
      password: 'password123',
    );
    expect(err3, contains('taken'));

    // Valid registration
    final err4 = await app.signUp(
      name: 'Clara',
      handle: '@clara',
      email: 'clara@verso.app',
      password: 'mypassword',
    );
    expect(err4, isNull);
    expect(app.currentUser?.email, 'clara@verso.app');
    expect(app.currentUser?.handle, '@clara');
    expect(app.shelf.any((p) => p.ownerEmail == 'clara@verso.app'), isTrue);

    // Duplicate email registration should fail
    final err5 = await app.signUp(
      name: 'Clara Two',
      handle: '@clara2',
      email: 'clara@verso.app',
      password: 'mypassword',
    );
    expect(err5, contains('already exists'));

    // Sign out & Sign in
    app.signOut();
    expect(app.currentUser, isNull);

    // Sign in wrong pass
    final err6 = await app.signIn('clara@verso.app', 'wrongpass');
    expect(err6, contains('Incorrect'));

    // Sign in correct pass
    final err7 = await app.signIn('clara@verso.app', 'mypassword');
    expect(err7, isNull);
    expect(app.currentUser?.email, 'clara@verso.app');
  });
}
