#!/bin/bash

# Now, run your flutterfire command (if you have one in your build process)
# For example, if you need to run `flutterfire configure` during build:


# Install Flutter
FLUTTER_VERSION="3.22.2" # Use a specific Flutter version
FLUTTER_DIR="/tmp/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION $FLUTTER_DIR
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Run Flutter doctor to confirm installation
flutter doctor

# Install Firebase CLI (if needed, depends on your Firebase setup)
npm install -g firebase-tools

# Activate FlutterFire CLI
dart pub global activate flutterfire_cli

# Add the Dart pub cache bin directory to PATH for the current shell session
export PATH="$PATH:$HOME/.pub-cache/bin"

# Generate firebase_options.dart
dart run flutterfire_cli:flutterfire configure --yes
flutterfire configure --project=taskflow-t95zd --platforms=web

# Build the Flutter web app
flutter pub get
flutter build web --release
