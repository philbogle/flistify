import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A dialog that displays help information.
class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});
  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Listify Help'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Listify helps you create, manage, and share lists by scanning images, dictating or pasting text, and autogenerating items with AI.',
            ),
            const SizedBox(height: 16),
            _HelpSection(icon: Icons.add, title: 'Add Item', content: 'Tap the "Add list item" button to add a new item to the list. Long press the button to add a header.'),
            const _HelpSection(
              icon: Icons.camera_alt_outlined,
              title: 'Scanning Lists & Objects',
              content:
                  'Tap the camera button to scan a list. Use your camera to take a picture of handwriting, printed text, or physical items. The AI will then create a list title and items based on the image content.',
            ),
            const _HelpSection(
              icon: Icons.keyboard_voice_outlined,
              title: 'Dictate or Paste Text',
              content:
                  'On the list detail screen, tap the microphone button. Paste text or use your mobile device\'s keyboard dictation feature into the dialog. The AI will convert this text into a structured list.',
            ),
            
            const ExpansionTile(
              initiallyExpanded: true,
              leading: Icon(Icons.info_outline),
              title: Text('List Detail Page Actions'),
              children: [
                _HelpSection(icon: Icons.add, title: 'Add Item', content: 'Tap the "+" button to add a new list.'),
                _HelpSection(icon: Icons.check, title: 'Mark Complete', content: 'Mark the entire list as complete.'),
                _HelpSection(icon: Icons.auto_awesome_outlined, title: 'Autogenerate Items', content: 'Automatically generate new items based on the list\'s title and existing content.'),
                _HelpSection(icon: Icons.sort, title: 'Autosort & Group', content: 'Automatically sort and group the items in the list.'),
                _HelpSection(icon: Icons.share, title: 'Share List', content: 'Share the list with others for collaborative editing.'),
                _HelpSection(icon: Icons.check_circle_outline, title: 'Delete Completed Items', content: 'Remove all completed items from the list.'),
                _HelpSection(icon: Icons.delete_outline, title: 'Delete List', content: 'Delete the entire list.'),
                
              ],
            ),
            if (kIsWeb)
              ExpansionTile(
                leading: const Icon(Icons.android),
                title: const Text('Android App Available'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'A native Android app is available with additional features and better performance. We are looking for testers! Please contact ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'philbogle@gmail.com',
                            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launchUrl(Uri.parse('mailto:philbogle@gmail.com'));
                              },
                          ),
                          const TextSpan(
                            text: ' for details.',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const ExpansionTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                      'Listify is a full-stack application built with modern technologies.\n\n'
                      '- Frontend: Flutter\n'
                      '- Backend & AI: Next.js, Genkit, Google Gemini\n'
                      '- Data Storage: Firebase Firestore\n'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}


/// A widget that displays a section of help information.
class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  /// Creates a help section with an icon, title, and content.
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.content,
  });
  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}