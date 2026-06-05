import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalImageCacheService {
  static const String _cacheFolderName = 'general_image_cache';
  
  // Track concurrent download futures to prevent redundant network fetches
  static final Map<String, Future<String?>> _activeDownloads = {};

  /// Generates a unique, deterministic local file path for a given URL
  /// within the application's document directory.
  static Future<String> getLocalPath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${directory.path}/$_cacheFolderName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // Convert the URL string to utf8 bytes and base64 encode it.
    // Replace non-alphanumeric characters to make it a safe filename.
    final bytes = utf8.encode(url);
    final base64Str = base64Encode(bytes);
    final filename = base64Str.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // Retain original file extension if possible, default to .png
    String ext = '.png';
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSeg = pathSegments.last;
        final dotIdx = lastSeg.lastIndexOf('.');
        if (dotIdx != -1 && dotIdx < lastSeg.length - 1) {
          final possibleExt = lastSeg.substring(dotIdx);
          if (possibleExt.length <= 6 && RegExp(r'^\.[a-zA-Z0-9]+$').hasMatch(possibleExt)) {
            ext = possibleExt;
          }
        }
      }
    } catch (_) {}

    return '${cacheDir.path}/$filename$ext';
  }

  /// Checks if the image is already downloaded and exists locally.
  /// If it exists, returns the local path. Otherwise, returns null.
  static Future<String?> getCachedPath(String url) async {
    if (url.isEmpty) return null;
    try {
      final path = await getLocalPath(url);
      if (await File(path).exists()) {
        return path;
      }
    } catch (_) {}
    return null;
  }

  /// Downloads an image from the URL and saves it to local disk.
  /// Returns the local file path on success, or null on failure.
  static Future<String?> cacheImage(String url) async {
    if (url.isEmpty) return null;

    if (_activeDownloads.containsKey(url)) {
      return _activeDownloads[url];
    }

    final downloadFuture = _downloadAndSave(url);
    _activeDownloads[url] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _activeDownloads.remove(url);
    }
  }

  static Future<String?> _downloadAndSave(String url) async {
    try {
      final path = await getLocalPath(url);
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        return path;
      }
    } catch (_) {
      // Return null on connection errors, timeout or empty bytes
    }
    return null;
  }

  /// Completely deletes all files in the general_image_cache directory.
  static Future<void> clearAllCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/$_cacheFolderName');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {
      // Safely ignore file system errors
    }
  }
}
