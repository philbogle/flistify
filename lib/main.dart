import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'models/list.dart';
import 'widgets/manual_add_list.dart';
import 'widgets/speak_list_dialog.dart';
import 'widgets/scan_list_dialog.dart';
import 'widgets/app_drawer.dart';
import 'widgets/list_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Listify'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sign in to manage your lists'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                        if (googleUser == null) {
                          // The user canceled the sign-in
                          return;
                        }
                        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                        final AuthCredential credential = GoogleAuthProvider.credential(
                          accessToken: googleAuth.accessToken,
                          idToken: googleAuth.idToken,
                        );
                        await FirebaseAuth.instance.signInWithCredential(credential);
                      } catch (e) {
                        print(e); // Handle sign-in errors
                      }
                    },
                    child: const Text('Sign in with Google'),
                  ),
                ],
              ),
            ),
          );
        }
        return const ListPage();
      },
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Stream<QuerySnapshot> _listsStream;
  bool _isCompletedExpanded = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _listsStream = FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _listsStream = const Stream.empty();
    }
  }

  Future<void> _scanAndCreateList(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageDataUri = 'data:image/jpeg;base64,$base64Image';

      final response = await http.post(
        Uri.parse('https://studio-ten-black.vercel.app/api/extractFromImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageDataUri': imageDataUri}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['parentListTitle'] ?? 'Scanned List';
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
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'completed': false,
        });
      } else {
        throw Exception('Failed to scan list: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to scan list: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _showManualAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const ManualAddList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Lists'),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _listsStream,
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final lists = snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                return ListModel.fromMap(document.id, data);
              }).toList();

              lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final activeLists = lists.where((list) => !list.completed).toList();
              final completedLists = lists.where((list) => list.completed).toList();

              return ListView(
                children: [
                  ...activeLists.map((list) => ListCard(list: list)),
                  if (completedLists.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      initiallyExpanded: _isCompletedExpanded,
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _isCompletedExpanded = expanded;
                        });
                      },
                      children: completedLists.map((list) => ListCard(key: ValueKey(list.id), list: list)).toList(),
                    ),
                  const SizedBox(height: 80), // Padding for FABs
                ],
              );
            },
          ),
          if (_isScanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning Image...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final ImageSource? source = await showDialog<ImageSource>(
                context: context,
                builder: (BuildContext context) {
                  return const ScanListDialog();
                },
              );
              if (source != null) {
                _scanAndCreateList(source);
              }
            },
            heroTag: 'scan',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const SpeakListDialog();
                },
              );
            },
            heroTag: 'speak',
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showManualAddSheet,
            heroTag: 'manual',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}