import 'package:flutter_test/flutter_test.dart';
import 'package:lifebuddy/main.dart';
import 'package:lifebuddy/widgets/hand_drawn_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// Starts the app and waits out the 1s pause plus the zoom and fade-in intro.
Future<void> pumpLoginPage(WidgetTester tester) async {
  // A tall screen, so every field and button is visible without scrolling.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const LifeBuddyApp());
  await tester.pump(const Duration(seconds: 1)); // the intro's start delay
  await tester.pumpAndSettle(); // zoom and fade-in
}

void main() {
  testWidgets('the app starts on the login page', (tester) async {
    await pumpLoginPage(tester);

    // Username and password only: the register fields are hidden.
    expect(find.byType(HandDrawnTextField), findsNWidgets(2));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });

  testWidgets('empty fields show validation errors', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Enter your username or email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('Register reveals the extra fields and Log in hides them', (
    tester,
  ) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    expect(find.byType(HandDrawnTextField), findsNWidgets(4));

    await tester.tap(find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(HandDrawnTextField), findsNWidgets(2));
  });
}
