import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:listify_mobile/main.dart';

import 'package:listify_mobile/widgets/help_dialog.dart';


/// A drawer that is displayed on the share screen.
class ShareDrawer extends StatelessWidget {
  const ShareDrawer({super.key});

  @override
  /// Builds the widget.
  ///
  /// This method constructs the UI for the drawer, including the header,
  /// navigation items (Home, Help), and a sign-out option if the user is authenticated.
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = user?.isAnonymous ?? true;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Listify',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (!isAnonymous)
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AuthGate(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              showDialog(
                context: context,
                builder: (context) => const HelpDialog(),
              );
            },
          ),
          if (user != null && !isAnonymous) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                FirebaseAuth.instance.signOut();
              },
            ),
          ]
        ],
      ),
    );
  }
}
