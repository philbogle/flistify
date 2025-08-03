
import 'package:flutter/material.dart';
import 'package:listify_mobile/services/google_tasks_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:listify_mobile/widgets/help_dialog.dart';


/// A drawer that displays application-level navigation and actions.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = user?.isAnonymous ?? true;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (user != null && !isAnonymous)
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName ?? 'User'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 50) : null,
              ),
            )
          else
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Listify',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
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
