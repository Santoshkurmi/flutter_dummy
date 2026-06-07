import 'dart:convert';
import 'package:flutter/services.dart';

class ChangelogVersion {
  final String version;
  final int? versionCode;
  final String date;
  final List<String> logs;

  const ChangelogVersion({
    required this.version,
    this.versionCode,
    required this.date,
    required this.logs,
  });

  factory ChangelogVersion.fromJson(Map<String, dynamic> json) {
    return ChangelogVersion(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int?,
      date: json['date'] as String,
      logs: List<String>.from(json['logs'] as List),
    );
  }
}

class ChangelogData {
  static List<ChangelogVersion> _versions = [];
  static String _versionName = '';
  static int _versionCode = 0;
  static Future<void>? _loadFuture;

  static List<ChangelogVersion> get versions => _versions;
  static String get versionName => _versionName;
  static int get versionCode => _versionCode;

  static Future<void> load() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  static Future<void> _load() async {
    try {
      final tomlString = await rootBundle.loadString('assets/changelog.toml');
      final lines = tomlString.split('\n');
      final List<ChangelogVersion> parsed = [];
      
      Map<String, dynamic>? currentVersion;
      List<String>? currentLogs;
      bool insideLogs = false;

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        if (line == '[[versions]]') {
          if (currentVersion != null) {
            if (currentLogs != null) {
              currentVersion['logs'] = currentLogs;
            }
            parsed.add(ChangelogVersion.fromJson(currentVersion));
          }
          currentVersion = {};
          currentLogs = null;
          insideLogs = false;
          continue;
        }

        if (currentVersion == null) continue;

        if (insideLogs) {
          if (line.endsWith(']')) {
            insideLogs = false;
            final content = line.substring(0, line.length - 1).trim();
            if (content.isNotEmpty) {
              final cleaned = _cleanString(content);
              if (cleaned.isNotEmpty) currentLogs?.add(cleaned);
            }
          } else {
            final cleaned = _cleanString(line);
            if (cleaned.isNotEmpty) currentLogs?.add(cleaned);
          }
          continue;
        }

        if (line.startsWith('logs = [')) {
          currentLogs = [];
          if (line.endsWith(']')) {
            final content = line.substring('logs = ['.length, line.length - 1).trim();
            if (content.isNotEmpty) {
              final cleaned = _cleanString(content);
              if (cleaned.isNotEmpty) currentLogs.add(cleaned);
            }
          } else {
            insideLogs = true;
          }
          continue;
        }

        final eqIdx = line.indexOf('=');
        if (eqIdx != -1) {
          final key = line.substring(0, eqIdx).trim();
          final valStr = line.substring(eqIdx + 1).trim();
          if (key == 'version') {
            currentVersion['version'] = _cleanString(valStr);
          } else if (key == 'versionCode') {
            currentVersion['versionCode'] = int.tryParse(valStr) ?? 0;
          } else if (key == 'date') {
            currentVersion['date'] = _cleanString(valStr);
          }
        }
      }

      if (currentVersion != null) {
        if (currentLogs != null) {
          currentVersion['logs'] = currentLogs;
        }
        parsed.add(ChangelogVersion.fromJson(currentVersion));
      }

      parsed.sort((a, b) {
        final codeA = a.versionCode ?? 0;
        final codeB = b.versionCode ?? 0;
        return codeB.compareTo(codeA);
      });

      _versions = parsed;
      if (parsed.isNotEmpty) {
        _versionName = parsed.first.version;
        _versionCode = parsed.first.versionCode ?? 0;
      }
    } catch (e) {
      _versions = [];
    }
  }

  static String _cleanString(String raw) {
    var s = raw.trim();
    if (s.endsWith(',')) s = s.substring(0, s.length - 1).trim();
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1);
    }
    return s;
  }
}
