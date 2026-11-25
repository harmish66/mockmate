import 'dart:convert';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/core/route.dart';
import 'package:mockmate/src/core/router.dart';
import 'package:mockmate/src/openapi/openapi_models.dart';

/// Imports OpenAPI 3.x specifications and registers mock routes automatically.
class OpenApiImporter {
  const OpenApiImporter();

  /// Parses OpenAPI 3.x JSON or Map and generates [OpenApiImportReport].
  OpenApiImportReport parse(dynamic source) {
    Map<String, dynamic> spec;
    if (source is String) {
      spec = jsonDecode(source) as Map<String, dynamic>;
    } else if (source is Map<String, dynamic>) {
      spec = source;
    } else {
      throw const FormatException(
          'OpenAPI spec must be JSON string or Map<String, dynamic>');
    }

    final openApiVersion =
        spec['openapi']?.toString() ?? spec['swagger']?.toString() ?? '3.0.0';
    final info = spec['info'] as Map<String, dynamic>? ?? {};
    final title = info['title']?.toString() ?? 'API Specification';
    final version = info['version']?.toString() ?? '1.0.0';

    final paths = spec['paths'] as Map<String, dynamic>? ?? {};
    final endpoints = <OpenApiEndpoint>[];
    final warnings = <String>[];

    if (!openApiVersion.startsWith('3.')) {
      warnings.add('Spec uses $openApiVersion; OpenAPI 3.x is recommended.');
    }

    final supportedMethods = {
      'get',
      'post',
      'put',
      'patch',
      'delete',
      'head',
      'options'
    };

    for (final pathEntry in paths.entries) {
      final openApiPath = pathEntry.key;
      final pathItem = pathEntry.value;
      if (pathItem is! Map<String, dynamic>) continue;

      // Convert OpenAPI path format /users/{id} to MockMate format /users/:id
      final mockMatePath = _convertPath(openApiPath);

      for (final methodEntry in pathItem.entries) {
        final methodKey = methodEntry.key.toLowerCase();
        if (!supportedMethods.contains(methodKey)) {
          if (!['summary', 'description', 'parameters', 'servers']
              .contains(methodKey)) {
            warnings.add(
                'Unsupported method or property "$methodKey" on $openApiPath');
          }
          continue;
        }

        final operation = methodEntry.value;
        if (operation is! Map<String, dynamic>) continue;

        final opId = operation['operationId']?.toString();
        final summary = operation['summary']?.toString();
        final desc = operation['description']?.toString();

        // Parse parameters
        final params = <OpenApiParameter>[];
        final rawParams = operation['parameters'] as List<dynamic>? ?? [];
        for (final p in rawParams) {
          if (p is Map<String, dynamic>) {
            params.add(
              OpenApiParameter(
                name: p['name']?.toString() ?? '',
                inLocation: p['in']?.toString() ?? 'query',
                required: p['required'] == true,
                example: p['example'],
                schemaType: p['schema']?['type']?.toString(),
              ),
            );
          }
        }

        // Parse responses
        final responses = <int, OpenApiResponseDefinition>{};
        final rawResponses =
            operation['responses'] as Map<String, dynamic>? ?? {};
        for (final rEntry in rawResponses.entries) {
          final statusCode = int.tryParse(rEntry.key) ?? 200;
          final rData = rEntry.value;
          if (rData is Map<String, dynamic>) {
            final rDesc = rData['description']?.toString() ?? '';
            dynamic exampleBody;

            // Content parsing
            final content = rData['content'] as Map<String, dynamic>?;
            if (content != null) {
              final jsonContent =
                  content['application/json'] as Map<String, dynamic>?;
              if (jsonContent != null) {
                exampleBody = jsonContent['example'] ??
                    jsonContent['examples']?['default']?['value'];
                if (exampleBody == null && jsonContent['schema'] != null) {
                  exampleBody = _generateDefaultFromSchema(
                      jsonContent['schema'] as Map<String, dynamic>);
                }
              }
            }

            responses[statusCode] = OpenApiResponseDefinition(
              statusCode: statusCode,
              description: rDesc,
              exampleBody: exampleBody,
            );
          }
        }

        endpoints.add(
          OpenApiEndpoint(
            path: mockMatePath,
            method: methodKey,
            operationId: opId,
            summary: summary,
            description: desc,
            parameters: params,
            responses: responses,
          ),
        );
      }
    }

    return OpenApiImportReport(
      title: title,
      version: version,
      endpoints: endpoints,
      warnings: warnings,
    );
  }

  /// Registers generated mock routes directly into [router].
  void registerToRouter(Router router, OpenApiImportReport report) {
    for (final ep in report.endpoints) {
      final method = HttpMethod.fromString(ep.method);
      // Pick best response (200, 201, or first available)
      OpenApiResponseDefinition? bestResponse =
          ep.responses[200] ?? ep.responses[201];
      if (bestResponse == null && ep.responses.isNotEmpty) {
        bestResponse = ep.responses.values.first;
      }

      final statusCode = bestResponse?.statusCode ?? 200;
      final body = bestResponse?.exampleBody ??
          {
            'message':
                ep.summary ?? 'Mocked ${ep.method.toUpperCase()} ${ep.path}'
          };

      router.register(
        MockRoute(
          method: method,
          pathPattern: ep.path,
          name: ep.operationId ?? '${ep.method.toUpperCase()} ${ep.path}',
          handler: (request) => MockResponse.json(
            statusCode: statusCode,
            body: body,
          ),
        ),
      );
    }
  }

  /// Converts /users/{id} to /users/:id
  static String _convertPath(String openApiPath) {
    return openApiPath.replaceAllMapped(RegExp(r'\{([a-zA-Z0-9_-]+)\}'),
        (match) {
      return ':${match.group(1)}';
    });
  }

  /// Generates sensible default data from OpenAPI schema if example is missing.
  static dynamic _generateDefaultFromSchema(Map<String, dynamic> schema) {
    final type = schema['type']?.toString();
    switch (type) {
      case 'object':
        final props = schema['properties'] as Map<String, dynamic>? ?? {};
        final map = <String, dynamic>{};
        for (final p in props.entries) {
          if (p.value is Map<String, dynamic>) {
            map[p.key] =
                _generateDefaultFromSchema(p.value as Map<String, dynamic>);
          } else {
            map[p.key] = null;
          }
        }
        return map;
      case 'array':
        final items = schema['items'] as Map<String, dynamic>?;
        if (items != null) {
          return [_generateDefaultFromSchema(items)];
        }
        return [];
      case 'string':
        return schema['example'] ?? 'sample_string';
      case 'integer':
      case 'number':
        return schema['example'] ?? 0;
      case 'boolean':
        return schema['example'] ?? true;
      default:
        return {};
    }
  }
}
