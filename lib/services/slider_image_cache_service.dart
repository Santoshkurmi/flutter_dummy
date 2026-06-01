import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SliderImageCacheService {
  static const String _urlsKey = 'cached_slider_urls';

  /// Generates a unique, deterministic local file path for a given URL
  /// within the application's document directory.
  static Future<String> getLocalPath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${directory.path}/slider_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // Convert the URL string to utf8 bytes and base64 encode it.
    // Replace non-alphanumeric characters to make it a safe filename.
    final bytes = utf8.encode(url);
    final base64Str = base64Encode(bytes);
    final filename = base64Str.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    return '${cacheDir.path}/$filename.png';
  }

  /// Retrieves the list of last successfully displayed slider image URLs
  /// from SharedPreferences.
  static Future<List<String>> getSavedUrls() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_urlsKey) ?? [];
  }

  /// Persists the list of active slider image URLs to SharedPreferences.
  static Future<void> saveUrls(List<String> urls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_urlsKey, urls);
  }

  /// Downloads an image from the URL and saves it to local disk.
  /// Returns the local file path on success, or null on failure.
  static Future<String?> cacheImage(String url) async {
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

  /// Clean up cache: remove any files in the slider_cache directory
  /// that do not correspond to any URL in [activeUrls].
  static Future<void> cleanUnusedCache(List<String> activeUrls) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/slider_cache');
      if (!await cacheDir.exists()) return;

      // Determine the exact local paths that need to be kept
      final Set<String> activePaths = {};
      for (final url in activeUrls) {
        final path = await getLocalPath(url);
        activePaths.add(path);
      }

      final List<FileSystemEntity> files = cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          if (!activePaths.contains(file.path)) {
            await file.delete();
          }
        }
      }
    } catch (_) {
      // Safely ignore file system errors during cleanup
    }
  }
}
