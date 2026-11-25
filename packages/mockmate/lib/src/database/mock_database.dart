import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/route.dart';
import 'package:mockmate/src/core/router.dart';
import 'package:mockmate/src/database/mock_resource.dart';

/// Database management system for MockMate stateful resources.
class MockDatabase {
  MockDatabase({required Router router}) : _router = router;

  final Router _router;
  final Map<String, MockResource> _resources = {};

  /// All registered resources.
  Map<String, MockResource> get resources => Map.unmodifiable(_resources);

  /// Registers a stateful CRUD REST resource at [basePath].
  /// Automatically registers GET, POST, PUT, PATCH, DELETE routes on the router.
  MockResource registerResource(
    String basePath, {
    List<Map<String, dynamic>>? initialData,
    String idField = 'id',
    bool autoIncrement = true,
  }) {
    var cleanPath = basePath.trim();
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    if (cleanPath.endsWith('/')) {
      cleanPath = cleanPath.substring(0, cleanPath.length - 1);
    }

    final resource = MockResource(
      basePath: cleanPath,
      initialData: initialData,
      idField: idField,
      autoIncrement: autoIncrement,
    );
    _resources[cleanPath] = resource;

    final itemPath = '$cleanPath/:$idField';

    // 1. GET collection (list, filter, sort, pagination)
    _router.register(
      MockRoute(
        method: HttpMethod.get,
        pathPattern: cleanPath,
        name: 'List $cleanPath',
        handler: (request) => resource.handleList(request),
      ),
    );

    // 2. GET item by ID
    _router.register(
      MockRoute(
        method: HttpMethod.get,
        pathPattern: itemPath,
        name: 'Get item $cleanPath',
        handler: (request) {
          final id = request.pathParameters[idField] ?? '';
          return resource.handleGetById(id);
        },
      ),
    );

    // 3. POST create item
    _router.register(
      MockRoute(
        method: HttpMethod.post,
        pathPattern: cleanPath,
        name: 'Create $cleanPath',
        handler: (request) => resource.handleCreate(request),
      ),
    );

    // 4. PUT replace item
    _router.register(
      MockRoute(
        method: HttpMethod.put,
        pathPattern: itemPath,
        name: 'Replace $cleanPath',
        handler: (request) {
          final id = request.pathParameters[idField] ?? '';
          return resource.handleReplace(id, request);
        },
      ),
    );

    // 5. PATCH partial update
    _router.register(
      MockRoute(
        method: HttpMethod.patch,
        pathPattern: itemPath,
        name: 'Patch $cleanPath',
        handler: (request) {
          final id = request.pathParameters[idField] ?? '';
          return resource.handlePatch(id, request);
        },
      ),
    );

    // 6. DELETE item
    _router.register(
      MockRoute(
        method: HttpMethod.delete,
        pathPattern: itemPath,
        name: 'Delete $cleanPath',
        handler: (request) {
          final id = request.pathParameters[idField] ?? '';
          return resource.handleDelete(id);
        },
      ),
    );

    return resource;
  }

  /// Resets all registered resources to their initial data.
  void resetAll() {
    for (final resource in _resources.values) {
      resource.reset();
    }
  }

  /// Exports current snapshot of all resources as a JSON-serializable Map.
  Map<String, List<Map<String, dynamic>>> exportState() {
    final state = <String, List<Map<String, dynamic>>>{};
    for (final entry in _resources.entries) {
      state[entry.key] = entry.value.all;
    }
    return state;
  }
}
