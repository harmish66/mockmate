import 'dart:convert';
import 'package:mockmate/src/core/request_response.dart';

/// In-memory stateful resource supporting full REST CRUD, pagination, filtering, and sorting.
class MockResource {
  MockResource({
    required this.basePath,
    List<Map<String, dynamic>>? initialData,
    this.idField = 'id',
    this.autoIncrement = true,
  }) {
    _initialData =
        (initialData ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    reset();
  }

  final String basePath;
  final String idField;
  final bool autoIncrement;

  late final List<Map<String, dynamic>> _initialData;
  final List<Map<String, dynamic>> _items = [];
  int _nextId = 1;

  /// Current records count.
  int get count => _items.length;

  /// Returns unmodifiable list of current records.
  List<Map<String, dynamic>> get all => List.unmodifiable(_items);

  /// Resets data to initial state.
  void reset() {
    _items.clear();
    for (final item in _initialData) {
      _items.add(Map<String, dynamic>.from(item));
    }
    _computeNextId();
  }

  void _computeNextId() {
    var maxId = 0;
    for (final item in _items) {
      final idVal = item[idField];
      if (idVal is int && idVal > maxId) {
        maxId = idVal;
      }
    }
    _nextId = maxId + 1;
  }

  /// Handles GET request on the collection (listing with search, filter, sort, pagination).
  MockResponse handleList(MockRequest request) {
    var result = List<Map<String, dynamic>>.from(_items);
    final params = request.queryParameters;

    // Search (?q=keyword)
    final q = params['q']?.toLowerCase().trim();
    if (q != null && q.isNotEmpty) {
      result = result.where((item) {
        return item.values
            .any((val) => val.toString().toLowerCase().contains(q));
      }).toList();
    }

    // Exact filtering on fields
    for (final entry in params.entries) {
      final key = entry.key;
      if (['page', 'limit', 'offset', 'sort', 'order', 'q'].contains(key)) {
        continue;
      }

      result = result.where((item) {
        final val = item[key]?.toString();
        return val == entry.value;
      }).toList();
    }

    // Sorting (?sort=fieldName&order=asc|desc)
    final sortField = params['sort'];
    if (sortField != null) {
      final isDesc = params['order']?.toLowerCase() == 'desc';
      result.sort((a, b) {
        final valA = a[sortField];
        final valB = b[sortField];
        if (valA == null && valB == null) return 0;
        if (valA == null) return isDesc ? 1 : -1;
        if (valB == null) return isDesc ? -1 : 1;

        if (valA is num && valB is num) {
          final cmp = valA.compareTo(valB);
          return isDesc ? -cmp : cmp;
        }
        final cmp = valA.toString().compareTo(valB.toString());
        return isDesc ? -cmp : cmp;
      });
    }

    // Pagination (?page=1&limit=10 or ?offset=0&limit=10)
    final total = result.length;
    var offset = 0;
    int? limit;

    if (params.containsKey('offset')) {
      offset = int.tryParse(params['offset'] ?? '0') ?? 0;
    } else if (params.containsKey('page')) {
      final page = int.tryParse(params['page'] ?? '1') ?? 1;
      final pageLimit = int.tryParse(params['limit'] ?? '10') ?? 10;
      offset = (page - 1) * pageLimit;
      limit = pageLimit;
    }

    if (params.containsKey('limit')) {
      limit = int.tryParse(params['limit'] ?? '10');
    }

    if (offset < 0) offset = 0;
    if (offset > result.length) offset = result.length;

    var paged = result.skip(offset);
    if (limit != null && limit > 0) {
      paged = paged.take(limit);
    }

    final pagedList = paged.toList();

    return MockResponse.json(
      statusCode: 200,
      body: {
        'total': total,
        'offset': offset,
        'limit': limit ?? total,
        'data': pagedList,
      },
    );
  }

  /// Handles GET request for a single record by ID.
  MockResponse handleGetById(String id) {
    final item = _findById(id);
    if (item == null) {
      return MockResponse.error(
          statusCode: 404, message: 'Resource with $idField=$id not found');
    }
    return MockResponse.json(statusCode: 200, body: {'data': item});
  }

  /// Handles POST request to create a new record.
  MockResponse handleCreate(MockRequest request) {
    dynamic bodyData;
    if (request.body is Map) {
      bodyData = Map<String, dynamic>.from(request.body as Map);
    } else {
      final str = request.bodyAsString;
      if (str != null && str.isNotEmpty) {
        bodyData = jsonDecode(str);
      }
    }

    if (bodyData == null || bodyData is! Map) {
      return MockResponse.error(
          statusCode: 400, message: 'Invalid or missing JSON request body');
    }

    final newRecord = Map<String, dynamic>.from(bodyData);
    if (!newRecord.containsKey(idField) || newRecord[idField] == null) {
      newRecord[idField] = autoIncrement
          ? _nextId++
          : DateTime.now().millisecondsSinceEpoch.toString();
    }

    _items.add(newRecord);
    return MockResponse.json(statusCode: 201, body: {'data': newRecord});
  }

  /// Handles PUT request to replace an existing record.
  MockResponse handleReplace(String id, MockRequest request) {
    final index = _findIndexById(id);
    if (index == -1) {
      return MockResponse.error(
          statusCode: 404, message: 'Resource with $idField=$id not found');
    }

    dynamic bodyData;
    if (request.body is Map) {
      bodyData = Map<String, dynamic>.from(request.body as Map);
    } else {
      final str = request.bodyAsString;
      if (str != null && str.isNotEmpty) {
        bodyData = jsonDecode(str);
      }
    }

    if (bodyData == null || bodyData is! Map) {
      return MockResponse.error(
          statusCode: 400, message: 'Invalid JSON request body');
    }

    final updated = Map<String, dynamic>.from(bodyData);
    // Preserve existing id if not supplied
    final existingId = _items[index][idField];
    updated[idField] = updated[idField] ?? existingId;

    _items[index] = updated;
    return MockResponse.json(statusCode: 200, body: {'data': updated});
  }

  /// Handles PATCH request to partially update fields.
  MockResponse handlePatch(String id, MockRequest request) {
    final index = _findIndexById(id);
    if (index == -1) {
      return MockResponse.error(
          statusCode: 404, message: 'Resource with $idField=$id not found');
    }

    dynamic bodyData;
    if (request.body is Map) {
      bodyData = Map<String, dynamic>.from(request.body as Map);
    } else {
      final str = request.bodyAsString;
      if (str != null && str.isNotEmpty) {
        bodyData = jsonDecode(str);
      }
    }

    if (bodyData == null || bodyData is! Map) {
      return MockResponse.error(
          statusCode: 400, message: 'Invalid JSON request body');
    }

    final current = Map<String, dynamic>.from(_items[index]);
    for (final entry in bodyData.entries) {
      current[entry.key.toString()] = entry.value;
    }

    _items[index] = current;
    return MockResponse.json(statusCode: 200, body: {'data': current});
  }

  /// Handles DELETE request to remove a record by ID.
  MockResponse handleDelete(String id) {
    final index = _findIndexById(id);
    if (index == -1) {
      return MockResponse.error(
          statusCode: 404, message: 'Resource with $idField=$id not found');
    }

    final removed = _items.removeAt(index);
    return MockResponse.json(
      statusCode: 200,
      body: {'message': 'Deleted successfully', 'deleted': removed},
    );
  }

  Map<String, dynamic>? _findById(String id) {
    for (final item in _items) {
      if (item[idField]?.toString() == id) {
        return item;
      }
    }
    return null;
  }

  int _findIndexById(String id) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i][idField]?.toString() == id) {
        return i;
      }
    }
    return -1;
  }
}
