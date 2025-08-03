import 'package:flutter/material.dart';

/// A utility class for handling links.
class LinkUtils {
  /// Extracts a URL from the given text.
  ///
  /// Returns the first URL found in the text, or null if no URL is found.
  static String? extractUrl(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  /// Formats the title of a list item.
  ///
  /// If the title contains a URL, it replaces the URL with an ellipsized version
  /// for display purposes.
  static String formatTitle(String title) {
    final url = extractUrl(title);
    if (url != null) {
      final displayUrl = url.replaceAll('https://', '').replaceAll('http://', '');
      String ellipsizedUrl = displayUrl;
      if (displayUrl.length > 24) {
        ellipsizedUrl = '${displayUrl.substring(0, 24)}...';
      }
      return title.replaceAll(url, ellipsizedUrl);
    }
    return title;
  }

  /// Returns the text style for a list item.
  ///
  /// If the title contains a URL, it returns a blue, underlined text style.
  /// Otherwise, it returns a style that applies a strikethrough if the item is completed.
  static TextStyle getTextStyle(String title, {bool completed = false}) {
    final url = extractUrl(title);
    if (url != null) {
      return const TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.blue,
      );
    }
    return TextStyle(
      decoration: completed ? TextDecoration.lineThrough : null,
      color: completed ? Colors.grey : null,
    );
  }
}
