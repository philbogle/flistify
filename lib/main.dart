import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'models/list.dart';
import 'widgets/list_card.dart';
import 'widgets/list_detail_screen.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/app_drawer.dart';
import 'widgets/manual_add_list.dart';
import 'widgets/scan_list_dialog.dart';
import 'widgets/take_picture_screen.dart';
import 'widgets/share_screen.dart';
import 'constants.dart';

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
      home: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    Widget page;

    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'share') {
      final shareId = uri.pathSegments.last;
      page = ShareScreen(shareId: shareId);
    } else {
      page = StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to Listify'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const Text(
                      'Your intelligent list-making companion',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    const FeatureHighlight(
                      icon: Icons.check_circle_outline,
                      title: 'Effortless Lists',
                      description: 'Quickly create and manage all of your to-do lists, shopping lists, and more.',
                    ),
                    const FeatureHighlight(
                      icon: Icons.camera_alt_outlined,
                      title: 'Scan from Camera',
                      description: 'Instantly turn photos of printed text, handwriting, or objects into digital lists.',
                    ),
                    const FeatureHighlight(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI-Powered Actions',
                      description: 'Let artificial intelligence automatically sort your lists and suggest new items.',
                    ),
                    const SizedBox(height: 20),
                    const FeatureHighlight(
                      icon: Icons.share,
                      title: 'List Sharing & Collaboration',
                      description: 'Share your lists with others and edit them together in real-time.',
                    ),
                    const SizedBox(height: 20),
                    const FeatureHighlight(
                      icon: Icons.devices,
                      title: 'Cross-Device Access',
                      description: 'Sign in to access your lists across all of your devices.',
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

                          if (googleUser == null) {
                            // User cancelled the sign-in
                            return;
                          }

                          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

                          final AuthCredential credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );
                          await FirebaseAuth.instance.signInWithCredential(credential);
                        } catch (e) {
                          print('Failed to sign in with Google: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to sign in with Google: $e'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Sign in with Google', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
          return const ListPage();
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: page,
      ),
    );
  }
}

class FeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureHighlight({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
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

  void _handleListCompleted(ListModel list, bool? completed) {
    if (completed == null) return;

    FirebaseFirestore.instance
        .collection('tasks')
        .doc(list.id)
        .update({'completed': completed});
  }

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

  Future<void> _scanAndCreateList() async {
    final XFile? image = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(),
      ),
    );

    if (image == null) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageDataUri = 'data:image/jpeg;base64,$base64Image';

      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/extractFromImage'),
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

  void _showManualAddSheet() async {
    final newTitle = await showModalBottomSheet<String>(
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

    if (newTitle != null && newTitle.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final newListRef = await FirebaseFirestore.instance.collection('tasks').add({
        'title': newTitle,
        'subtasks': [],
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'completed': false,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListDetailScreen(listId: newListRef.id),
          ),
        );
      }
    }
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
                  if (activeLists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Card(
                        margin: EdgeInsets.zero, // Reset margin as padding is applied to parent
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lightbulb_outline, size: 48, color: Colors.amber),
                              SizedBox(height: 16),
                              Text(
                                'No lists yet!',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Tap the ➕ button to add a list manually.',
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tap the 📷 button to scan a list.',
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ...activeLists.map((list) => ListCard(key: ValueKey(list.id), list: list, onCompleted: (value) => _handleListCompleted(list, value))),
                  if (completedLists.isNotEmpty)
                    ExpansionTile(
                      title: const Text('Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      trailing: null,
                      initiallyExpanded: _isCompletedExpanded,
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _isCompletedExpanded = expanded;
                        });
                      },
                      children: completedLists.map((list) => ListCard(key: ValueKey(list.id), list: list, onCompleted: (value) => _handleListCompleted(list, value))).toList(),
                    ),
                  const SizedBox(height: 140), // Padding for FABs
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
            onPressed: _scanAndCreateList,
            heroTag: 'scan',
            child: const Icon(Icons.camera_alt),
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
