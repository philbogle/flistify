
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SpeakListDialog extends StatefulWidget {
  const SpeakListDialog({super.key});

  @override
  State<SpeakListDialog> createState() => _SpeakListDialogState();
}

class _SpeakListDialogState extends State<SpeakListDialog> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  bool _manuallyStopped = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
    );
    setState(() {});
  }

  void _startListening() async {
    _manuallyStopped = false;
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 1), // Listen for up to a minute
      pauseFor: const Duration(seconds: 10), // Tolerate longer pauses
      onSoundLevelChange: null,
      cancelOnError: false,
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    _manuallyStopped = true;
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && _isListening && !_manuallyStopped) {
      // Auto-restart listening if it stopped unexpectedly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isListening && !_manuallyStopped) {
          _startListening();
        }
      });
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      final recognized = result.recognizedWords.trim();
      if (recognized.isEmpty) return;
      if (_lastWords.isEmpty) {
        _lastWords = recognized;
      } else if (!recognized.startsWith(_lastWords)) {
        // If the new recognized text doesn't start with the old, append with a space
        _lastWords = (_lastWords + ' ' + recognized).trim();
      } else {
        // If recognized text starts with _lastWords, just update (covers incremental recognition)
        _lastWords = recognized;
      }
    });
  }

  void _createList() async {
    if (_lastWords.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://studio-ten-black.vercel.app/api/extractFromText'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dictatedText': _lastWords}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['parentListTitle'] ?? 'Spoken List';
        final subitems = (data['extractedSubitems'] as List<dynamic>? ?? [])
            .map((item) => {
                  'id': DateTime.now().millisecondsSinceEpoch.toString() +
                      (item['title'] ?? ''),
                  'title': item['title'] ?? '',
                  'completed': false,
                })
            .toList();

        await FirebaseFirestore.instance.collection('tasks').add({
          'title': title,
          'subtasks': subitems,
          'createdAt': Timestamp.now(),
          'userId': user.uid,
          'completed': false,
        });

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to create list: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
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
          Text(_lastWords, style: const TextStyle(fontSize: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isListening ? _stopListening : _startListening,
          child: Icon(_isListening ? Icons.mic_off : Icons.mic),
        ),
        ElevatedButton(
          onPressed: _lastWords.isNotEmpty ? _createList : null,
          child: const Text('Create List'),
        ),
      ],
    );
  }
}
