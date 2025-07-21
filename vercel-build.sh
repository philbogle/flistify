#!/bin/bash

# Install Flutter
FLUTTER_VERSION="3.22.2" # Use a specific Flutter version
FLUTTER_DIR="/tmp/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION $FLUTTER_DIR
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Run Flutter doctor to confirm installation
flutter doctor

# Generate firebase_options.dart
flutterfire configure --yes

# Build the Flutter web app
flutter pub get
flutter build web --release
