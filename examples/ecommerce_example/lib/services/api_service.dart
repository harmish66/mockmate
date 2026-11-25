import 'dart:convert';
import 'package:ecommerce_example/models/product.dart';
import 'package:mockmate/mockmate.dart';

/// Service interfacing with the stateful MockMate backend.
class ApiService {
  ApiService(this.mockMate);

  final MockMate mockMate;

  Future<List<Product>> getProducts({String? query, String? category}) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (category != null && category.isNotEmpty && category != 'All')
      queryParams['category'] = category;

    final uri = Uri(
        path: '/api/products',
        queryParameters: queryParams.isEmpty ? null : queryParams);
    final req = MockRequest(method: HttpMethod.get, uri: uri);
    final res = await mockMate.handleRequest(req);

    if (res.isError) {
      throw Exception(res.statusMessage ?? 'Failed to load products');
    }

    final data = res.bodyAsJson;
    final list =
        data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    return list
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Product> getProductById(int id) async {
    final req = MockRequest(
      method: HttpMethod.get,
      uri: Uri.parse('/api/products/$id'),
    );
    final res = await mockMate.handleRequest(req);

    if (res.isError) {
      throw Exception('Product with id $id not found');
    }

    final body = res.bodyAsJson as Map<String, dynamic>;
    return Product.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<Product> createProduct(Product product) async {
    final req = MockRequest(
      method: HttpMethod.post,
      uri: Uri.parse('/api/products'),
      body: product.toJson(),
    );
    final res = await mockMate.handleRequest(req);

    if (res.isError) {
      throw Exception('Failed to create product: ${res.statusMessage}');
    }

    final body = res.bodyAsJson as Map<String, dynamic>;
    return Product.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<Product> updateProduct(Product product) async {
    final req = MockRequest(
      method: HttpMethod.put,
      uri: Uri.parse('/api/products/${product.id}'),
      body: product.toJson(),
    );
    final res = await mockMate.handleRequest(req);

    if (res.isError) {
      throw Exception('Failed to update product: ${res.statusMessage}');
    }

    final body = res.bodyAsJson as Map<String, dynamic>;
    return Product.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<void> deleteProduct(int id) async {
    final req = MockRequest(
      method: HttpMethod.delete,
      uri: Uri.parse('/api/products/$id'),
    );
    final res = await mockMate.handleRequest(req);

    if (res.isError) {
      throw Exception('Failed to delete product: ${res.statusMessage}');
    }
  }
}
