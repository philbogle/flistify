import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/widgets/list_detail_screen.dart';

class ShareScreen extends StatefulWidget {
  final String shareId;

  const ShareScreen({super.key, required this.shareId});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  @override
  void initState() {
    super.initState();
    _signInAndNavigate();
  }

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
              builder: (context) => ListDetailScreen(listId: listId),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
