/// Supported HTTP methods in MockMate.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options;

  /// Parses a string into an [HttpMethod].
  static HttpMethod fromString(String method) {
    switch (method.trim().toUpperCase()) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'PATCH':
        return HttpMethod.patch;
      case 'DELETE':
        return HttpMethod.delete;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Converts the enum to uppercase HTTP verb string.
  String toVerb() => name.toUpperCase();
}
