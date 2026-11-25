/// Parsed OpenAPI specification endpoint definition.
class OpenApiEndpoint {
  const OpenApiEndpoint({
    required this.path,
    required this.method,
    this.operationId,
    this.summary,
    this.description,
    this.parameters = const [],
    this.responses = const {},
  });

  final String path;
  final String method;
  final String? operationId;
  final String? summary;
  final String? description;
  final List<OpenApiParameter> parameters;
  final Map<int, OpenApiResponseDefinition> responses;
}

/// OpenAPI parameter definition.
class OpenApiParameter {
  const OpenApiParameter({
    required this.name,
    required this.inLocation,
    this.required = false,
    this.schemaType,
    this.example,
  });

  final String name;
  final String inLocation; // 'path', 'query', 'header'
  final bool required;
  final String? schemaType;
  final dynamic example;
}

/// OpenAPI response metadata and examples.
class OpenApiResponseDefinition {
  const OpenApiResponseDefinition({
    required this.statusCode,
    required this.description,
    this.exampleBody,
    this.schemaType,
  });

  final int statusCode;
  final String description;
  final dynamic exampleBody;
  final String? schemaType;
}

/// Diagnostic report from OpenAPI parsing.
class OpenApiImportReport {
  OpenApiImportReport({
    required this.title,
    required this.version,
    required this.endpoints,
    this.warnings = const [],
  });

  final String title;
  final String version;
  final List<OpenApiEndpoint> endpoints;
  final List<String> warnings;

  int get totalEndpoints => endpoints.length;
}
