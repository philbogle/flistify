import 'package:flutter/material.dart';

class LinkUtils {
  static String? extractUrl(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

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
