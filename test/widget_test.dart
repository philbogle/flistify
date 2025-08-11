// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listify_mobile/main.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  testWidgets('App renders welcome screen when signed out', (WidgetTester tester) async {
    // Note: flutter_test_config.dart initializes the test binding and Firebase once
    // for all tests. We do not re-initialize Firebase here to avoid duplicate init.

    // Ensure a sufficiently large window to avoid overflow in tests
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.window.physicalSizeTestValue = const Size(1080, 1920);

    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    // Use a mock FirebaseAuth with no user signed in
    final mockAuth = MockFirebaseAuth(signedIn: false);

    // Build the app with injected auth
    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));
    // Allow the authStateChanges() StreamBuilder to build. Use a finite timeout
    // so tests never hang indefinitely.
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

    // Verify that the welcome text is shown for signed-out users
    expect(find.text('Welcome to Listify'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
