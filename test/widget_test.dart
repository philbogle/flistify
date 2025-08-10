// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:listify_mobile/main.dart';
import 'package:listify_mobile/firebase_options.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  testWidgets('App renders welcome screen when signed out', (WidgetTester tester) async {
    // Ensure bindings and initialize Firebase for the test
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Use a mock FirebaseAuth with no user signed in
    final mockAuth = MockFirebaseAuth(signedIn: false);

    // Build the app with injected auth
    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));
    await tester.pumpAndSettle();

    // Verify that the welcome text is shown for signed-out users
    expect(find.text('Welcome to Listify'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
