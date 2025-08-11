import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listify_mobile/widgets/link_utils.dart';

void main() {
  group('LinkUtils.extractUrl', () {
    test('returns null when no url present', () {
      expect(LinkUtils.extractUrl('no links here'), isNull);
    });

    test('returns the first http url', () {
      final text = 'see http://example.com and also https://flutter.dev';
      expect(LinkUtils.extractUrl(text), 'http://example.com');
    });

    test('returns the first https url', () {
      final text = 'prefix https://example.com/page?x=1 end';
      expect(LinkUtils.extractUrl(text), 'https://example.com/page?x=1');
    });
  });

  group('LinkUtils.formatTitle', () {
    test('does nothing if no url in title', () {
      const title = 'Buy milk and eggs';
      expect(LinkUtils.formatTitle(title), title);
    });

    test('replaces url with stripped scheme and ellipsis when long', () {
      const longUrl =
          'https://very.long.domain.example.com/path/to/a/really/long/resource?id=123456';
      const title = 'Check this $longUrl now';
      final formatted = LinkUtils.formatTitle(title);

      // Should remove scheme and ellipsize to 24 characters plus ...
      expect(
        formatted,
        startsWith('Check this '),
      );
      final withoutPrefix = formatted.replaceFirst('Check this ', '');
      expect(withoutPrefix.endsWith(' now'), isTrue);
      final urlDisplay = withoutPrefix.substring(0, withoutPrefix.length - ' now'.length);
      expect(urlDisplay.length, 27); // 24 chars + '...'
      expect(urlDisplay.endsWith('...'), isTrue);
    });

    test('replaces url with stripped scheme when short', () {
      const shortUrl = 'https://example.com';
      const title = 'Open $shortUrl please';
      final formatted = LinkUtils.formatTitle(title);
      expect(formatted, 'Open example.com please');
    });
  });

  group('LinkUtils.getTextStyle', () {
    test('returns blue underlined when url present', () {
      final style = LinkUtils.getTextStyle('see https://example.com');
      expect(style.decoration, TextDecoration.underline);
      expect(style.color, equals(Colors.blue));
    });

    test('returns strike-through when completed and no url', () {
      final style = LinkUtils.getTextStyle('no link here', completed: true);
      expect(style.decoration, TextDecoration.lineThrough);
    });

    test('returns normal when not completed and no url', () {
      final style = LinkUtils.getTextStyle('no link here', completed: false);
      expect(style.decoration, isNull);
    });
  });
}

