import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verso/main.dart';

void main() {
  testWidgets('welcome -> exhibit -> shelf -> auth user separation flow', (tester) async {
    await tester.pumpWidget(const VersoApp(enableDiskPersistence: false));
    expect(find.text('Skip'), findsOneWidget);

    // Skip welcome -> Exhibit
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Exhibit'), findsWidgets);

    // Navigate to Shelf for default user (@ila)
    await tester.tap(find.text('Shelf'));
    await tester.pumpAndSettle();
    expect(find.text('Salt & Silence'), findsOneWidget);

    // Open Auth screen and create a new user account
    await tester.tap(find.byIcon(Icons.person_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create shelf'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Clara');
    await tester.enterText(fields.at(1), '@clara');
    await tester.enterText(fields.at(2), 'clara@verso.app');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.ensureVisible(find.text('Create my Shelf'));
    await tester.tap(find.text('Create my Shelf'));
    await tester.pumpAndSettle();

    // Verify Clara's Shelf only has her own starter draft, not @ila's books
    await tester.tap(find.text('Shelf'));
    await tester.pumpAndSettle();
    expect(find.text('First page on the water'), findsOneWidget);
    expect(find.text('Salt & Silence'), findsNothing);
  });
}
