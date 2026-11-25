import 'dart:convert';
import 'package:mockmate/src/core/request_response.dart';

/// Single JSON fixture definition with associated metadata.
class FixtureDefinition {
  FixtureDefinition({
    required this.id,
    required this.name,
    required this.data,
    this.description,
  });

  final String id;
  final String name;
  final dynamic data;
  final String? description;

  /// Returns data formatted as JSON string.
  String toJsonString({bool pretty = true}) {
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    }
    return jsonEncode(data);
  }

  /// Creates a [MockResponse] from this fixture.
  MockResponse toResponse({
    int statusCode = 200,
    Map<String, String>? headers,
    Duration? delay,
  }) {
    return MockResponse.json(
      statusCode: statusCode,
      body: data,
      headers: headers,
      delay: delay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'data': data,
    };
  }

  factory FixtureDefinition.fromJson(Map<String, dynamic> json) {
    return FixtureDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      data: json['data'],
    );
  }
}
