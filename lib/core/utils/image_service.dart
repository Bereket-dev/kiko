import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImageService
// ─────────────────────────────────────────────────────────────────────────────
//
// Picks, compresses, and stores lead images to app-private storage.
//
// Spec requirements:
//   - Compress longest side to 1280 px at ~75% quality
//   - Store as WebP (Android-preferred) with JPEG fallback
//   - Files go to app-private directory (not accessible to other apps)
//   - Max 3 images per lead (enforced in LeadsRepository)
// ─────────────────────────────────────────────────────────────────────────────

class ImageService {
  const ImageService();

  static const _maxDimension = 1280;
  static const _quality = 75;

  /// Compress [sourceFile] and save to app-private storage under [leadId].
  /// Returns the path of the saved file.
  Future<String> processAndStore({
    required File sourceFile,
    required String leadId,
    required int position,
  }) async {
    final dir = await _leadImagesDir(leadId);
    final destPath = p.join(dir.path, 'img_${position}_${_timestamp()}.webp');

    final result = await FlutterImageCompress.compressAndGetFile(
      sourceFile.absolute.path,
      destPath,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      quality: _quality,
      format: CompressFormat.webp,
      keepExif: false,
    );

    if (result == null) {
      // WebP failed — fall back to JPEG.
      final jpegPath = p.join(
          dir.path, 'img_${position}_${_timestamp()}.jpg');
      final jpegResult = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        jpegPath,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        quality: _quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (jpegResult == null) {
        throw Exception('Image compression failed for ${sourceFile.path}');
      }
      return jpegResult.path;
    }

    return result.path;
  }

  /// Delete a stored image file. Ignores missing files.
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Delete all images for a lead.
  Future<void> deleteAllForLead(String leadId) async {
    try {
      final dir = await _leadImagesDir(leadId);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Directory> _leadImagesDir(String leadId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'lead_images', leadId));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _timestamp() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
