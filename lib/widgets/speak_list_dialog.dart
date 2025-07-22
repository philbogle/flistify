
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeakListDialog extends StatefulWidget {
  const SpeakListDialog({super.key});

  @override
  State<SpeakListDialog> createState() => _SpeakListDialogState();
}

class _SpeakListDialogState extends State<SpeakListDialog> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _transcript = ''; // The full text being built
  String _baseTranscriptForCurrentSession = ''; // The text when listening started
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) {
      setState(() {});
      if (_speechEnabled) {
        _startListening();
      }
    }
  }

  void _startListening() async {
    // Store the current transcript to build upon it.
    _baseTranscriptForCurrentSession = _transcript.isNotEmpty ? '$_transcript ' : '';

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
    );
    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _transcript = '$_baseTranscriptForCurrentSession${result.recognizedWords}';
    });
  }

  void _createList() async {
    if (_transcript.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/extractFromText'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dictatedText': _transcript.trim()}),
      );

      Navigator.of(context).pop(); // Dismiss loading indicator

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['parentListTitle'] ?? 'Spoken List';
        final subitems = (data['extractedSubitems'] as List<dynamic>? ?? [])
            .map((item) {
              final newSubitemRef = FirebaseFirestore.instance.collection('tasks').doc().collection('subtasks').doc();
              return {
                'id': newSubitemRef.id,
                'title': item['title'] ?? '',
                'completed': false,
              };
            }).toList();

        await FirebaseFirestore.instance.collection('tasks').add({
          'title': title,
          'subtasks': subitems,
          'createdAt': Timestamp.now(),
          'userId': user.uid,
          'completed': false,
        });

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss the dialog
        }
      } else {
        throw Exception('Failed to create list: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading indicator on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create list: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Speak a List'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isListening
                ? 'Listening...'
                : _speechEnabled
                    ? 'Tap the microphone to start speaking.'
                    : 'Speech not available, please grant permissions.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8.0),
            constraints: const BoxConstraints(minHeight: 100),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(_transcript, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _speechEnabled ? (_isListening ? _stopListening : _startListening) : null,
          child: Icon(_isListening ? Icons.mic_off : Icons.mic),
        ),
        ElevatedButton(
          onPressed: _transcript.trim().isNotEmpty ? _createList : null,
          child: const Text('Create List'),
        ),
      ],
    );
  }
}
