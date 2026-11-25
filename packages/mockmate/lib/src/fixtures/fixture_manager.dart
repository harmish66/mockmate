import 'dart:convert';
import 'dart:io';
import 'package:mockmate/src/fixtures/fixture_definition.dart';
import 'package:path/path.dart' as p;

/// Manages registration, validation, and safe file loading of JSON fixtures.
class FixtureManager {
  FixtureManager({String? baseDirectory})
      : baseDirectory = baseDirectory ?? 'mockmate/fixtures';

  final String baseDirectory;
  final Map<String, FixtureDefinition> _fixtures = {};

  /// All registered fixtures mapped by ID.
  Map<String, FixtureDefinition> get fixtures => Map.unmodifiable(_fixtures);

  /// Registers an in-memory fixture definition.
  void register(FixtureDefinition fixture) {
    _fixtures[fixture.id] = fixture;
  }

  /// Retrieves fixture by ID.
  FixtureDefinition? get(String id) => _fixtures[id];

  /// Safely resolves a fixture file path, preventing directory traversal.
  File _resolveSafeFile(String relativePath) {
    // Check for directory traversal attempts
    if (relativePath.contains('..') ||
        relativePath.startsWith('/') ||
        relativePath.startsWith('\\')) {
      throw SecurityException('Unsafe fixture path detected: $relativePath');
    }

    final normalized = p.normalize(p.join(baseDirectory, relativePath));
    final baseNormalized = p.normalize(baseDirectory);

    if (!p.isWithin(baseNormalized, normalized) &&
        normalized != baseNormalized) {
      throw SecurityException(
          'Path traversal attempt outside base directory: $relativePath');
    }

    return File(normalized);
  }

  /// Loads fixture from disk safely.
  Future<FixtureDefinition> loadFromFile(String relativePath,
      {String? id}) async {
    final file = _resolveSafeFile(relativePath);
    if (!await file.exists()) {
      throw FileSystemException('Fixture file does not exist', file.path);
    }

    final content = await file.readAsString();
    final dynamic decoded = jsonDecode(content);
    final fixtureId =
        id ?? p.withoutExtension(relativePath).replaceAll(p.separator, '/');

    final fixture = FixtureDefinition(
      id: fixtureId,
      name: p.basename(relativePath),
      data: decoded,
    );

    _fixtures[fixture.id] = fixture;
    return fixture;
  }

  /// Exports all registered fixtures to a JSON Map.
  Map<String, dynamic> exportAll() {
    final map = <String, dynamic>{};
    for (final entry in _fixtures.entries) {
      map[entry.key] = entry.value.toJson();
    }
    return map;
  }

  /// Imports fixtures from a map.
  void importAll(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      if (entry.value is Map<String, dynamic>) {
        final fix =
            FixtureDefinition.fromJson(entry.value as Map<String, dynamic>);
        _fixtures[fix.id] = fix;
      }
    }
  }

  /// Clears in-memory fixtures.
  void clear() {
    _fixtures.clear();
  }
}

/// Security exception for prohibited file access attempts.
class SecurityException implements Exception {
  const SecurityException(this.message);
  final String message;

  @override
  String toString() => 'SecurityException: $message';
}
