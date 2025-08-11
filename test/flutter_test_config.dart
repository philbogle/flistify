import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listify_mobile/firebase_options.dart';

// This file runs before any tests in the `test/` directory.
// It ensures Flutter bindings and Firebase are initialized for widget tests
// that depend on Firebase (e.g., FirebaseAuth/FirebaseFirestore).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Ensure test binding for widget tests (must use TestWidgetsFlutterBinding)
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize the default Firebase app once for all tests
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Fallback: try default initialization without options (useful in tests)
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // keep not initialized; we'll surface in tests if needed
    }
  }

  await testMain();
}

