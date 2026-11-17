import "dart:io";
import "dart:typed_data";
import "package:flutter/foundation.dart";

/// Pure Dart in-memory logo cache for thermal receipt printers.
/// Mirrors LogoCache.java from the thermal printer specification.
class LogoCache {
  static final Map<String, Uint8List> _cache = {};
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);

  /// Retrieves or downloads logo image bytes from URL.
  static Future<Uint8List?> getLogoBytes(String url) async {
    if (url.trim().isEmpty) return null;

    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytesBuilder = BytesBuilder();
        await for (final chunk in response) {
          bytesBuilder.add(chunk);
        }
        final bytes = bytesBuilder.toBytes();
        _cache[url] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint("LogoCache download failed for '$url': $e");
    }
    return null;
  }

  /// Clears in-memory logo cache.
  static void clear() {
    _cache.clear();
  }
}
