import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class AvatarCache {
  AvatarCache._();

  static final Map<String, String?> _memo = <String, String?>{};

  static Future<Directory> _cacheDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/cache/avatars');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _safeName(String url) {
    // Use simple hash to avoid large integer issues on web
    int h = 0x811c9dc5; // 32-bit FNV offset basis (web-safe)
    const int prime = 0x01000193; // 32-bit FNV prime
    for (final c in url.codeUnits) {
      h ^= c;
      h = (h * prime) & 0xFFFFFFFF; // keep 32-bit
    }
    final hex = h.toRadixString(16).padLeft(16, '0');
    // Attempt to keep a reasonable extension (may help some platforms)
    final uri = Uri.tryParse(url);
    String ext = 'img';
    if (uri != null) {
      final seg = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last.toLowerCase()
          : '';
      final m = RegExp(r"\.(png|jpg|jpeg|webp|gif|bmp|ico)").firstMatch(seg);
      if (m != null) ext = m.group(1)!;
    }
    return 'av_$hex.$ext';
  }

  /// Ensures avatar at [url] is cached locally and returns the file path.
  /// On failure, returns null.
  static Future<String?> getPath(String url) async {
    if (url.isEmpty) return null;
    if (_memo.containsKey(url)) return _memo[url];
    try {
      final dir = await _cacheDir();
      final name = _safeName(url);
      final file = File('${dir.path}/$name');
      if (await file.exists()) {
        _memo[url] = file.path;
        return file.path;
      }
      // Download and save
      final res = await http.get(Uri.parse(url));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await file.writeAsBytes(res.bodyBytes, flush: true);
        _memo[url] = file.path;
        return file.path;
      }
    } catch (_) {}
    _memo[url] = null;
    return null;
  }

  static Future<void> evict(String url) async {
    try {
      final dir = await _cacheDir();
      final name = _safeName(url);
      final file = File('${dir.path}/$name');
      if (await file.exists()) await file.delete();
    } catch (_) {}
    _memo.remove(url);
  }
}
