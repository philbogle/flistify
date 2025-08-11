# Listify Mobile

A Flutter application for creating, managing, and sharing lists. The application uses Firebase for backend services, including Firestore for data storage and Firebase Authentication for user management.

## Features

*   **List Management:** Create, edit, and delete lists and their items.
*   **AI-Assisted Functionality:**
    *   **Autosort:** Automatically sorts list items.
    *   **Autogenerate:** Suggests and adds new items to a list based on its title.
*   **Image-to-List:** Converts a photo of a list into a digital format within the app.
*   **Anonymous Sharing:** Share lists via a unique link. Recipients can view and edit the shared list without logging in, facilitated by Firebase Anonymous Authentication.
*   **Google Authentication:** Supports user sign-in via Google accounts.
*   **Export to Google Tasks:** Send your list and items to a new Google Tasks list with one tap.

## Export to Google Tasks

Listify can export any list to Google Tasks. This creates a new task list in your Google account with each subitem as an individual task (completed items are marked as completed).

- Where to find it:
  - Open a list, tap the three-dot menu in the app bar, then choose "Export to Google Tasks".
- Prerequisites:
  - Sign in with Google in the app. The app will request the Google Tasks scope when exporting.
  - Network access must be available to reach Google APIs.
- What happens:
  - A new Google Task List is created using your Listify list title.
  - Each subitem is exported as a Task with its completed status.
- Platform notes:
  - The export option is hidden on Web builds (kIsWeb) because Google Sign-In flows are limited for this feature on web.
  - Use Android, iOS, macOS, Windows, or Linux builds for exporting.
- Troubleshooting:
  - If you see a message about sign-in, ensure you’re signed into Listify with a Google account.
  - If export fails, the app shows a Snackbar with the error. Try again after checking connectivity and Google permissions.

## Technology

*   **Frontend:** Flutter
*   **Backend Services:**
    *   Firebase Authentication (Google Sign-In, Anonymous)
    *   Cloud Firestore (Database)
*   **AI Features:** Powered by a separate backend service.

## Setup and Running the Project

1.  Ensure the Flutter SDK is installed.
2.  Configure a Firebase project and add the `firebase_options.dart` file to the `lib/` directory.
3.  Install dependencies: `flutter pub get`
4.  Run the application: `flutter run`
