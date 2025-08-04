import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/tasks/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listify_mobile/models/list.dart' as app_list;
import 'package:listify_mobile/models/subitem.dart';
import 'package:http/http.dart' as http;

class GoogleTasksService {
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  GoogleTasksService()
      : _googleSignIn = GoogleSignIn(scopes: [TasksApi.tasksScope]),
        _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  Future<TasksApi?> _getTasksApi() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not signed in.");
      return null;
    }

    GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) {
      print("Google user not signed in silently. Attempting interactive sign-in.");
      googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Interactive Google sign-in failed.");
        return null;
      }
    }

    final authHeaders = await googleUser.authHeaders;
    final accessTokenData = authHeaders['Authorization']!.split(' ')[1];

    final AccessToken accessToken = AccessToken(
      'Bearer',
      accessTokenData,
      DateTime.now().add(const Duration(hours: 1)).toUtc(), // Assuming token valid for 1 hour
    );

    final AccessCredentials credentials = AccessCredentials(
      accessToken,
      null, // refreshToken
      [TasksApi.tasksScope], // scopes
    );

    final client = authenticatedClient(http.Client(), credentials);
    return TasksApi(client);
  }

  Future<void> exportTasks(app_list.ListModel list) async {
    final tasksApi = await _getTasksApi();
    if (tasksApi == null) {
      print("Failed to get Tasks API client.");
      return;
    }

    // Create a new task list in Google Tasks
    final TaskList googleTaskList = TaskList()..title = list.title;
    final createdTaskList = await tasksApi.tasklists.insert(googleTaskList);

    if (createdTaskList.id != null) {
      for (final Subitem subitem in list.subitems) {
        final Task googleTask = Task()
          ..title = subitem.title
          ..status = subitem.completed ? 'completed' : 'needsAction';
        await tasksApi.tasks.insert(googleTask, createdTaskList.id!);
      }
    }
    print("List exported to Google Tasks successfully!");
  }
}
