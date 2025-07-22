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
