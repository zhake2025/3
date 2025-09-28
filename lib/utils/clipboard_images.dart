import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardImages {
  static const MethodChannel _channel = MethodChannel('app.clipboard');

  static Future<List<String>> getImagePaths() async {
    try {
      final res = await _channel.invokeMethod<List<dynamic>>('getClipboardImages');
      if (res == null) return const [];
      return res.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }
}

