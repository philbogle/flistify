#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Vercel Build Script ---"

# --- 1. Install Flutter ---
FLUTTER_VERSION="3.22.2" # Use a specific Flutter version
FLUTTER_DIR="/tmp/flutter"

echo "Checking for Flutter installation in $FLUTTER_DIR..."
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter version $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION $FLUTTER_DIR
else
  echo "Flutter already exists, skipping clone."
fi

# Add Flutter's bin directory to PATH for this session
export PATH="$FLUTTER_DIR/bin:$PATH"
echo "Flutter added to PATH."

# Run Flutter doctor to confirm installation
echo "Running flutter doctor..."
flutter doctor

# --- 2. Install Firebase CLI ---
echo "Installing Firebase CLI globally..."
npm install -g firebase-tools
echo "Firebase CLI installed."

# --- 3. Authenticate Firebase CLI using the CI token ---
# This is the crucial step for CI/CD environments.
if [ -z "$FIREBASE_TOKEN" ]; then
  echo "Error: FIREBASE_TOKEN environment variable is not set."
  echo "Please generate a Firebase CI token (firebase login:ci) and add it to Vercel project environment variables."
  exit 1
else
  echo "Authenticating Firebase CLI with provided token..."
  firebase use --token "$FIREBASE_TOKEN" default # Use 'default' or your project alias if you have one
  echo "Firebase CLI authenticated."
fi


# --- 4. Activate FlutterFire CLI ---
echo "Activating FlutterFire CLI globally..."
dart pub global activate flutterfire_cli
echo "FlutterFire CLI activated."

# Add the Dart pub cache bin directory to PATH for the current shell session
export PATH="$PATH:$HOME/.pub-cache/bin"
echo "Dart pub cache added to PATH."

# --- 5. Generate firebase_options.dart ---
echo "Generating firebase_options.dart using flutterfire_cli..."
dart run flutterfire_cli:flutterfire configure \
  --project=taskflow-t95zd \
  --platforms=web \
  --yes # Automatically answer yes to prompts
echo "firebase_options.dart generated."

# --- 6. Build the Flutter web app ---
echo "Getting Flutter package dependencies..."
flutter pub get
echo "Building Flutter web app for release..."
flutter build web --release
echo "Flutter web app built successfully."

echo "--- Vercel Build Script Finished Successfully ---"
