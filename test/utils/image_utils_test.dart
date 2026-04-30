import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:medbox/utils/image_utils.dart';

void main() {
  // ── readableSize ──────────────────────────────────────────────────────────────

  group('ImageUtils.readableSize', () {
    test('formats raw bytes under 1 KB', () {
      expect(ImageUtils.readableSize(512), '512 B');
    });

    test('formats exactly 1 KB', () {
      expect(ImageUtils.readableSize(1024), '1.0 KB');
    });

    test('formats 1.5 KB correctly', () {
      expect(ImageUtils.readableSize(1536), '1.5 KB');
    });

    test('formats 1500 bytes as 1.5 KB (from docs example)', () {
      expect(ImageUtils.readableSize(1500), '1.5 KB');
    });

    test('formats exactly 1 MB', () {
      expect(ImageUtils.readableSize(1024 * 1024), '1.0 MB');
    });

    test('formats 2 MB correctly', () {
      expect(ImageUtils.readableSize(2 * 1024 * 1024), '2.0 MB');
    });

    test('formats 2_097_152 bytes as 2.0 MB (from docs example)', () {
      expect(ImageUtils.readableSize(2097152), '2.0 MB');
    });

    test('formats fractional MB correctly', () {
      expect(ImageUtils.readableSize((1.5 * 1024 * 1024).round()), '1.5 MB');
    });
  });

  // ── isSupportedFormat ─────────────────────────────────────────────────────────

  group('ImageUtils.isSupportedFormat', () {
    test('accepts .jpg', () {
      expect(ImageUtils.isSupportedFormat('photo.jpg'), isTrue);
    });

    test('accepts .jpeg', () {
      expect(ImageUtils.isSupportedFormat('photo.jpeg'), isTrue);
    });

    test('accepts .png', () {
      expect(ImageUtils.isSupportedFormat('photo.png'), isTrue);
    });

    test('accepts .webp', () {
      expect(ImageUtils.isSupportedFormat('photo.webp'), isTrue);
    });

    test('accepts .heic', () {
      expect(ImageUtils.isSupportedFormat('photo.heic'), isTrue);
    });

    test('rejects .gif', () {
      expect(ImageUtils.isSupportedFormat('animation.gif'), isFalse);
    });

    test('rejects .pdf', () {
      expect(ImageUtils.isSupportedFormat('document.pdf'), isFalse);
    });

    test('rejects .txt', () {
      expect(ImageUtils.isSupportedFormat('notes.txt'), isFalse);
    });

    test('rejects .bmp', () {
      expect(ImageUtils.isSupportedFormat('image.bmp'), isFalse);
    });

    test('accepts uppercase extension (case-insensitive)', () {
      expect(ImageUtils.isSupportedFormat('photo.JPG'), isTrue);
    });

    test('accepts mixed-case extension', () {
      expect(ImageUtils.isSupportedFormat('photo.Jpeg'), isTrue);
    });

    test('handles path with directory separators', () {
      expect(ImageUtils.isSupportedFormat('/data/user/photos/box.png'), isTrue);
    });
  });

  // ── compressAndResize ─────────────────────────────────────────────────────────

  group('ImageUtils.compressAndResize', () {
    test('falls back to original bytes when the file contains corrupt data', () async {
      // decodeImage returns null for non-image bytes →
      // the function must return the original bytes unchanged.
      final file = File('${Directory.systemTemp.path}/medbox_test_corrupt.bin');
      final junkBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE]);
      await file.writeAsBytes(junkBytes);

      try {
        final result = await ImageUtils.compressAndResize(file);
        expect(result, equals(junkBytes));
      } finally {
        if (await file.exists()) await file.delete();
      }
    });

    test('falls back to original bytes when the file is empty', () async {
      final file = File('${Directory.systemTemp.path}/medbox_test_empty.bin');
      await file.writeAsBytes(Uint8List(0));

      try {
        final result = await ImageUtils.compressAndResize(file);
        expect(result, isEmpty);
      } finally {
        if (await file.exists()) await file.delete();
      }
    });
  });
}
