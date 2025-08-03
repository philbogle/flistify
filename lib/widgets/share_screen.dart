import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/widgets/list_detail_screen.dart';
import 'package:listify_mobile/widgets/share_drawer.dart';

/// A screen that displays a shared list.
class ShareScreen extends StatefulWidget {
  final String shareId;

  const ShareScreen({super.key, required this.shareId});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

/// State class for [ShareScreen].
class _ShareScreenState extends State<ShareScreen> {
  @override
  /// Initializes the state of the widget.
  ///
  /// This method is called once when the widget is inserted into the widget tree.
  /// It triggers the anonymous sign-in and navigation process.
  void initState() {
    super.initState();
    _signInAndNavigate();
  }

  /// Signs the user in anonymously and navigates to the list detail screen.
  ///
  /// This method attempts to sign in the user anonymously using Firebase Authentication.
  /// Upon successful sign-in, it queries Firestore to find the shared list
  /// based on the provided `shareId` and then navigates to the `ListDetailScreen`.
  /// If the list is not found or an error occurs during sign-in, an error message is displayed.
  Future<void> _signInAndNavigate() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('shareId', isEqualTo: widget.shareId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final listId = querySnapshot.docs.first.id;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ListDetailScreen(listId: listId, isShared: true),
            ),
          );
        } else {
          _showError('List not found.');
        }
      }
    } catch (e) {
      _showError('Could not sign in to view the list.');
    }
  }

  /// Shows an error message to the user.
  ///
  /// Displays a [SnackBar] with the given [message] and then pops the current context.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared List'),
      ),
      drawer: const ShareDrawer(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
