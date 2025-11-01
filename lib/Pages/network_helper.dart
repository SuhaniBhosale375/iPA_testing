// lib/network_helper.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NetworkHelper {
  static const _cacheKey = 'backend_base_url';
  static const int _port = 5213;

  /// Returns a base URL like "http://192.168.1.10:5213/api/Employees"
  static Future<String?> discoverBackend({int port = _port}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Try cached value first
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      // test cached quickly
      try {
        final testUri = Uri.parse('$cached/login?empId=ping&password=ping');
        final resp = await http.get(testUri).timeout(const Duration(seconds: 1));
        if (resp.statusCode == 200) return cached;
      } catch (_) {
        // cached failed, proceed to full discovery
      }
    }

    // 2) Get current wifi IP to derive subnet
    final info = NetworkInfo();
    final wifiIp = await info.getWifiIP(); // e.g. "192.168.1.12" or "10.211.52.42"
    if (wifiIp == null) return null;

    final lastDot = wifiIp.lastIndexOf('.');
    if (lastDot < 0) return null;
    final subnetPrefix = wifiIp.substring(0, lastDot + 1); // "192.168.1."

    // 3) Build candidate IP list (1..254)
    final candidates = List.generate(254, (i) => '$subnetPrefix${i + 1}');

    // 4) Scan in batches with limited concurrency for speed
    const batchSize = 20; // concurrency level
    for (var start = 0; start < candidates.length; start += batchSize) {
      final end = (start + batchSize) < candidates.length ? (start + batchSize) : candidates.length;
      final batch = candidates.sublist(start, end);

      // Fire off all requests in this batch
      final futures = batch.map((ip) async {
        final url = Uri.parse('http://$ip:$port/api/system/ip');
        try {
          final resp = await http.get(url).timeout(const Duration(milliseconds: 700));
          if (resp.statusCode == 200) {
            final data = json.decode(resp.body);
            final serverIp = data['ip'];
            if (serverIp != null) {
              final base = 'http://$serverIp:$port/api/Employees';
              // cache it
              await prefs.setString(_cacheKey, base);
              return base;
            }
          }
        } catch (_) {
          // ignore
        }
        return null;
      }).toList();

      // wait batch
      final results = await Future.wait(futures);
      // check if any returned a non-null URL
      for (final r in results) {
        if (r != null) return r;
      }
      // else continue with next batch
    }

    return null; // not found
  }

  /// Clear cached backend (call when you want to force rescan)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
