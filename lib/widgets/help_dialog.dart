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
            const _HelpSection(
              icon: Icons.add_box_outlined,
              title: 'Creating Lists Manually',
              content:
                  'Tap the "Add" button and select "Enter manually" to create a new list. You can name your list and add items directly.',
            ),
            const _HelpSection(
              icon: Icons.camera_alt_outlined,
              title: 'Scanning Lists & Objects',
              content:
                  'Select "Scan" from the "Add" menu. Use your camera to take a picture of handwriting, printed text, or physical items. The AI will then create a list title and items based on the image content.',
            ),
            const _HelpSection(
              icon: Icons.keyboard_voice_outlined,
              title: 'Dictate or Paste Text',
              content:
                  'Choose "Dictate or Paste" from the "Add" menu. Paste text or use your mobile device\'s keyboard dictation feature into the dialog. The AI will convert this text into a structured list.',
            ),
            const _HelpSection(
              icon: Icons.auto_awesome_outlined,
              title: 'Autogenerating Items',
              content:
                  'Use the "Autogenerate" button on a list card or the "Autogenerate Items" menu option. The AI suggests new items based on the list\'s title and existing content.',
            ),
            const _HelpSection(
              icon: Icons.link,
              title: 'URL Previews',
              content:
                  'When you add a URL to a list item, a preview of the link will be automatically generated, showing the title, description, and an image from the website.',
            ),
            const _HelpSection(
              icon: Icons.touch_app,
              title: 'Tapping Behavior',
              content:
                  'On the main screen, tapping a list\'s title or a sub-item will navigate to its detail screen. On the list detail screen, tapping the list title or an item will allow you to edit it. Changes are saved automatically when the field loses focus.',
            ),
            const ExpansionTile(
              leading: Icon(Icons.info_outline),
              title: Text('List Detail Page Actions'),
              children: [
                _HelpSection(icon: Icons.check, title: 'Mark Complete', content: 'Mark the entire list as complete.'),
                _HelpSection(icon: Icons.auto_awesome_outlined, title: 'Autogenerate Items', content: 'Automatically generate new items based on the list\'s title and existing content.'),
                _HelpSection(icon: Icons.sort, title: 'Autosort Items', content: 'Automatically sort the items in the list.'),
                _HelpSection(icon: Icons.camera_alt_outlined, title: 'Scan More Items', content: 'Scan another image and add the items to the current list.'),
                _HelpSection(icon: Icons.mic_none, title: 'Dictate or Paste', content: 'Add items to the list by dictating or pasting text.'),
                _HelpSection(icon: Icons.share, title: 'Share List', content: 'Share the list with others.'),
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