import 'dart:convert';

/// Rules for redacting sensitive headers and body fields to avoid exposing secrets.
class RedactionRules {
  RedactionRules({
    Set<String>? sensitiveHeaders,
    Set<String>? sensitiveBodyKeys,
    this.mask = '[REDACTED]',
  })  : sensitiveHeaders = sensitiveHeaders ??
            {
              'authorization',
              'cookie',
              'set-cookie',
              'x-api-key',
              'apikey',
              'proxy-authorization',
              'x-auth-token',
            },
        sensitiveBodyKeys = sensitiveBodyKeys ??
            {
              'password',
              'passcode',
              'secret',
              'token',
              'access_token',
              'refresh_token',
              'api_key',
              'credit_card',
              'card_number',
              'cvv',
              'ssn',
            };

  final Set<String> sensitiveHeaders;
  final Set<String> sensitiveBodyKeys;
  final String mask;

  /// Redacts sensitive entries from a headers map.
  Map<String, String> redactHeaders(Map<String, String> headers) {
    final result = <String, String>{};
    for (final entry in headers.entries) {
      if (sensitiveHeaders.contains(entry.key.toLowerCase())) {
        result[entry.key] = mask;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Redacts sensitive fields from a body (Map, List, or JSON string).
  Object? redactBody(Object? body) {
    if (body == null) return null;
    if (body is Map) {
      final map = <String, dynamic>{};
      for (final entry in body.entries) {
        final keyStr = entry.key.toString();
        if (sensitiveBodyKeys.contains(keyStr.toLowerCase())) {
          map[keyStr] = mask;
        } else {
          map[keyStr] = redactBody(entry.value);
        }
      }
      return map;
    }
    if (body is List) {
      return body.map(redactBody).toList();
    }
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        final redacted = redactBody(decoded);
        return jsonEncode(redacted);
      } catch (_) {
        // Not a JSON string
        return body;
      }
    }
    return body;
  }
}
