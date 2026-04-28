import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Helpers for compressing and resizing images before saving locally.
abstract final class ImageUtils {
  /// Maximum width or height after resize. Larger images are scaled down
  /// proportionally so neither dimension exceeds this value.
  static const int kMaxDimension = 1024;

  /// JPEG quality used when re-encoding (0 = smallest, 100 = lossless).
  static const int kJpegQuality = 80;

  /// Reads [file], resizes so neither dimension exceeds [maxDimension], then
  /// re-encodes as JPEG at [quality]. Returns compressed bytes.
  ///
  /// Falls back to the original bytes if decoding fails (e.g. unsupported
  /// format), so callers are always guaranteed a valid result.
  static Future<Uint8List> compressAndResize(
    File file, {
    int maxDimension = kMaxDimension,
    int quality = kJpegQuality,
  }) async {
    final bytes = await file.readAsBytes();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes; // unsupported format — return as-is

    final resized = img.copyResize(
      decoded,
      width:  decoded.width >= decoded.height ? maxDimension : -1,
      height: decoded.height > decoded.width  ? maxDimension : -1,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  /// Returns a human-readable file size string.
  ///   1500      → "1.5 KB"
  ///   2_097_152 → "2.0 MB"
  static String readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Returns true when the image at [path] is likely a supported format
  /// based on its file extension.
  static bool isSupportedFormat(String path) {
    final ext = path.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(ext);
  }
}
