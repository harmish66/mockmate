import 'package:dio/dio.dart';
import 'package:mockmate/mockmate.dart';
import 'package:test/test.dart';

void main() {
  group('Core Routing & Matching', () {
    late MockMate mock;

    setUp(() {
      mock = MockMate(delayProvider: const ZeroDelayProvider());
    });

    tearDown(() {
      mock.dispose();
    });

    test('matches exact path and method', () async {
      mock.get(
          '/api/health', (req) => MockResponse.json(body: {'status': 'ok'}));

      final req = MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/health'));
      final res = await mock.handleRequest(req);

      expect(res.statusCode, equals(200));
      expect(res.bodyAsJson['status'], equals('ok'));
    });

    test('extracts path parameters', () async {
      mock.get('/api/users/:userId/posts/:postId', (req) {
        return MockResponse.json(body: {
          'userId': req.pathParameters['userId'],
          'postId': req.pathParameters['postId'],
        });
      });

      final req = MockRequest(
        method: HttpMethod.get,
        uri: Uri.parse('http://localhost/api/users/42/posts/108'),
      );
      final res = await mock.handleRequest(req);

      expect(res.statusCode, equals(200));
      expect(res.bodyAsJson['userId'], equals('42'));
      expect(res.bodyAsJson['postId'], equals('108'));
    });

    test('supports wildcard routes', () async {
      mock.get('/assets/*', (req) {
        return MockResponse.text('Asset: ${req.pathParameters['wildcard']}');
      });

      final req = MockRequest(
        method: HttpMethod.get,
        uri: Uri.parse('http://localhost/assets/images/logo.png'),
      );
      final res = await mock.handleRequest(req);

      expect(res.statusCode, equals(200));
      expect(res.bodyAsString, equals('Asset: images/logo.png'));
    });

    test('enforces query parameters and headers when required', () async {
      mock.get(
        '/api/search',
        (req) => MockResponse.json(body: {'found': true}),
        requiredQueryParams: {'q': 'flutter'},
        requiredHeaders: {'x-custom': 'secret'},
      );

      final badReq = MockRequest(
        method: HttpMethod.get,
        uri: Uri.parse('http://localhost/api/search?q=dart'),
      );
      final badRes = await mock.handleRequest(badReq);
      expect(badRes.statusCode, equals(404));

      final goodReq = MockRequest(
        method: HttpMethod.get,
        uri: Uri.parse('http://localhost/api/search?q=flutter'),
        headers: {'x-custom': 'secret'},
      );
      final goodRes = await mock.handleRequest(goodReq);
      expect(goodRes.statusCode, equals(200));
      expect(goodRes.bodyAsJson['found'], isTrue);
    });

    test('prioritizes higher priority routes', () async {
      mock.get('/api/data', (req) => MockResponse.text('low'), priority: 0);
      mock.get('/api/data', (req) => MockResponse.text('high'), priority: 10);

      final req = MockRequest(
          method: HttpMethod.get, uri: Uri.parse('http://localhost/api/data'));
      final res = await mock.handleRequest(req);

      expect(res.bodyAsString, equals('high'));
    });

    test('fallback route handles unmatched requests', () async {
      mock.router.setFallback((req) => MockResponse.text('fallback'));

      final req = MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/not-registered'));
      final res = await mock.handleRequest(req);

      expect(res.statusCode, equals(200));
      expect(res.bodyAsString, equals('fallback'));
    });
  });

  group('Response Builder', () {
    test('builds JSON responses', () {
      final res = MockResponse.json(statusCode: 201, body: {'id': 1});
      expect(res.statusCode, equals(201));
      expect(res.headers['content-type'], contains('application/json'));
      expect(res.bodyAsJson['id'], equals(1));
    });

    test('builds text and empty responses', () {
      final textRes = MockResponse.text('Plain text');
      expect(textRes.statusCode, equals(200));
      expect(textRes.bodyAsString, equals('Plain text'));

      final emptyRes = MockResponse.empty(statusCode: 204);
      expect(emptyRes.statusCode, equals(204));
      expect(emptyRes.body, isNull);
    });

    test('builds byte responses', () {
      final bytesRes =
          MockResponse.bytes([1, 2, 3, 4], contentType: 'image/png');
      expect(bytesRes.statusCode, equals(200));
      expect(bytesRes.headers['content-type'], equals('image/png'));
      expect(bytesRes.bodyAsBytes, equals([1, 2, 3, 4]));
    });

    test('builds error responses', () {
      final errRes = MockResponse.error(statusCode: 500, message: 'Crash');
      expect(errRes.statusCode, equals(500));
      expect(errRes.isError, isTrue);
      expect(errRes.bodyAsJson['error'], equals('Crash'));
    });
  });

  group('Scenario Engine', () {
    late MockMate mock;

    setUp(() {
      mock = MockMate(delayProvider: const ZeroDelayProvider());
    });

    tearDown(() {
      mock.dispose();
    });

    test('switches between scenarios', () async {
      mock.get('/api/items', (req) => MockResponse.json(body: ['default']));
      mock.scenario('items', {
        'success': MockResponse.json(body: ['item1', 'item2']),
        'empty': MockResponse.json(body: []),
        'serverError': MockResponse.error(statusCode: 500, message: 'DB down'),
      });

      // Default (success)
      var res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/items')));
      expect(res.bodyAsJson, equals(['item1', 'item2']));

      // Switch route to empty
      mock.activateRouteScenario('items', 'empty');
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/items')));
      expect(res.bodyAsJson, equals([]));

      // Switch to serverError
      mock.activateRouteScenario('items', 'serverError');
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/items')));
      expect(res.statusCode, equals(500));
    });

    test('emits scenario change events', () async {
      final events = <ScenarioChangeEvent>[];
      mock.scenarioManager.onScenarioChange.listen(events.add);

      mock.activateScenario('offline');
      mock.activateRouteScenario('auth', 'unauthorized');

      await Future<void>.delayed(Duration.zero);
      expect(events.length, equals(2));
      expect(events[0].isGlobal, isTrue);
      expect(events[0].newScenario, equals('offline'));
      expect(events[1].routeName, equals('auth'));
      expect(events[1].newScenario, equals('unauthorized'));
    });
  });

  group('Network Simulator', () {
    test('offline mode throws MockOfflineException', () async {
      final mock = MockMate(delayProvider: const ZeroDelayProvider());
      mock.get('/api/test', (req) => MockResponse.text('ok'));
      mock.network.setOffline(true);

      await expectLater(
        () => mock.handleRequest(MockRequest(
            method: HttpMethod.get,
            uri: Uri.parse('http://localhost/api/test'))),
        throwsA(isA<MockOfflineException>()),
      );
      mock.dispose();
    });

    test('timeout profile triggers MockTimeoutException', () async {
      final mock = MockMate(
        delayProvider: const ZeroDelayProvider(),
        defaultNetworkProfile: const NetworkProfile(
          name: 'TimeoutProfile',
          preset: NetworkPreset.custom,
          minLatency: Duration(milliseconds: 100),
          maxLatency: Duration(milliseconds: 100),
          timeout: Duration(milliseconds: 50),
        ),
      );

      mock.get('/api/test', (req) => MockResponse.text('ok'));

      await expectLater(
        () => mock.handleRequest(MockRequest(
            method: HttpMethod.get,
            uri: Uri.parse('http://localhost/api/test'))),
        throwsA(isA<MockTimeoutException>()),
      );
      mock.dispose();
    });
  });

  group('Stateful Mock Database', () {
    late MockMate mock;

    setUp(() {
      mock = MockMate(delayProvider: const ZeroDelayProvider());
      mock.resource(
        '/api/products',
        initialData: [
          {'id': 1, 'name': 'MacBook Pro', 'price': 2000, 'category': 'tech'},
          {'id': 2, 'name': 'iPhone 15', 'price': 1000, 'category': 'tech'},
          {'id': 3, 'name': 'Coffee Mug', 'price': 20, 'category': 'home'},
        ],
      );
    });

    tearDown(() {
      mock.dispose();
    });

    test('GET list, search, filter, sort, pagination', () async {
      // 1. List all
      var res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products')));
      expect(res.bodyAsJson['total'], equals(3));
      expect(res.bodyAsJson['data'].length, equals(3));

      // 2. Filter (?category=home)
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products?category=home')));
      expect(res.bodyAsJson['total'], equals(1));
      expect(res.bodyAsJson['data'][0]['name'], equals('Coffee Mug'));

      // 3. Search (?q=phone)
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products?q=phone')));
      expect(res.bodyAsJson['total'], equals(1));
      expect(res.bodyAsJson['data'][0]['name'], equals('iPhone 15'));

      // 4. Sort (?sort=price&order=desc)
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse(
              'http://localhost/api/products?sort=price&order=desc')));
      expect(res.bodyAsJson['data'][0]['price'], equals(2000));
      expect(res.bodyAsJson['data'][2]['price'], equals(20));

      // 5. Pagination (?page=1&limit=2)
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products?page=1&limit=2')));
      expect(res.bodyAsJson['data'].length, equals(2));
    });

    test('GET by ID', () async {
      final res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products/1')));
      expect(res.statusCode, equals(200));
      expect(res.bodyAsJson['data']['name'], equals('MacBook Pro'));

      final missing = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products/999')));
      expect(missing.statusCode, equals(404));
    });

    test('POST create, PUT replace, PATCH update, DELETE remove', () async {
      // POST create
      var res = await mock.handleRequest(MockRequest(
        method: HttpMethod.post,
        uri: Uri.parse('http://localhost/api/products'),
        body: {'name': 'iPad Pro', 'price': 1200},
      ));
      expect(res.statusCode, equals(201));
      final newId = res.bodyAsJson['data']['id'];
      expect(newId, equals(4));

      // PATCH update
      res = await mock.handleRequest(MockRequest(
        method: HttpMethod.patch,
        uri: Uri.parse('http://localhost/api/products/4'),
        body: {'price': 1100},
      ));
      expect(res.statusCode, equals(200));
      expect(res.bodyAsJson['data']['price'], equals(1100));
      expect(res.bodyAsJson['data']['name'], equals('iPad Pro'));

      // DELETE
      res = await mock.handleRequest(MockRequest(
        method: HttpMethod.delete,
        uri: Uri.parse('http://localhost/api/products/4'),
      ));
      expect(res.statusCode, equals(200));

      // Verify gone
      res = await mock.handleRequest(MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/products/4')));
      expect(res.statusCode, equals(404));
    });

    test('reset restores initial data', () async {
      await mock.handleRequest(MockRequest(
        method: HttpMethod.post,
        uri: Uri.parse('http://localhost/api/products'),
        body: {'name': 'Extra item'},
      ));
      expect(mock.database.resources['/api/products']!.count, equals(4));

      mock.database.resetAll();
      expect(mock.database.resources['/api/products']!.count, equals(3));
    });
  });

  group('Request Recorder & Redaction & Replay', () {
    late MockMate mock;

    setUp(() {
      mock = MockMate(delayProvider: const ZeroDelayProvider());
    });

    tearDown(() {
      mock.dispose();
    });

    test('records transactions and redacts sensitive tokens and passwords',
        () async {
      mock.post('/api/login', (req) {
        return MockResponse.json(
          body: {'token': 'secret-jwt-token-12345', 'status': 'logged_in'},
          headers: {'authorization': 'Bearer secret-jwt-token-12345'},
        );
      });

      await mock.handleRequest(
        MockRequest(
          method: HttpMethod.post,
          uri: Uri.parse('http://localhost/api/login'),
          headers: {
            'authorization': 'Basic secretcredentials',
            'x-api-key': 'my-secret-key'
          },
          body: {'username': 'testuser', 'password': 'supersecretpassword'},
        ),
      );

      expect(mock.requestHistory.length, equals(1));
      final tx = mock.requestHistory.first;

      // Verify headers redacted
      expect(tx.request.headers['authorization'], equals('[REDACTED]'));
      expect(tx.request.headers['x-api-key'], equals('[REDACTED]'));

      // Verify body redacted
      final reqBody = tx.request.body as Map;
      expect(reqBody['username'], equals('testuser'));
      expect(reqBody['password'], equals('[REDACTED]'));

      // Verify response redacted
      expect(tx.response!.headers['authorization'], equals('[REDACTED]'));
      final resJson = tx.response!.bodyAsJson as Map;
      expect(resJson['token'], equals('[REDACTED]'));
      expect(resJson['status'], equals('logged_in'));
    });

    test('replays transaction successfully', () async {
      mock.get('/api/counter', (req) => MockResponse.json(body: {'count': 1}));

      final req = MockRequest(
          method: HttpMethod.get,
          uri: Uri.parse('http://localhost/api/counter'));
      await mock.handleRequest(req);

      final original = mock.requestHistory.first;
      final replay = await mock.replayEngine.replay(
        transaction: original,
        handler: (r) => mock.handleRequest(r),
      );

      expect(replay.isMatch, isTrue);
      expect(replay.replayedResponse?.statusCode, equals(200));
    });
  });

  group('Dio Adapter Integration', () {
    test('intercepts requests with Dio', () async {
      final mock = MockMate(delayProvider: const ZeroDelayProvider());
      mock.get(
          '/api/users',
          (req) => MockResponse.json(body: [
                {'id': 1, 'name': 'Alice'}
              ]));

      final dio = Dio();
      dio.interceptors.add(MockMateDioAdapter(mock));

      final response = await dio.get<dynamic>('https://example.com/api/users');
      expect(response.statusCode, equals(200));
      expect(response.data, isA<List>());
      expect((response.data as List).first['name'], equals('Alice'));

      mock.dispose();
    });

    test('handles errors with Dio badResponse', () async {
      final mock = MockMate(delayProvider: const ZeroDelayProvider());
      mock.get(
          '/api/fail',
          (req) =>
              MockResponse.error(statusCode: 500, message: 'Server Exploded'));

      final dio = Dio();
      dio.interceptors.add(MockMateDioAdapter(mock));

      await expectLater(
        () => dio.get<dynamic>('https://example.com/api/fail'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'statusCode', 500),
        ),
      );
      mock.dispose();
    });
  });

  group('HTTP Package Adapter Integration', () {
    test('intercepts requests with MockMateHttpClient', () async {
      final mock = MockMate(delayProvider: const ZeroDelayProvider());
      mock.get('/api/info', (req) => MockResponse.text('Hello from MockMate'));

      final client = MockMateHttpClient(mockMate: mock);
      final response =
          await client.get(Uri.parse('https://example.com/api/info'));

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Hello from MockMate'));

      client.close();
      mock.dispose();
    });
  });

  group('OpenAPI Importer', () {
    test('imports OpenAPI 3.0 specification correctly', () {
      final mock = MockMate(delayProvider: const ZeroDelayProvider());
      const openApiJson = '''
      {
        "openapi": "3.0.0",
        "info": {"title": "Pet Store API", "version": "1.0.0"},
        "paths": {
          "/pets": {
            "get": {
              "summary": "List all pets",
              "responses": {
                "200": {
                  "description": "A paged array of pets",
                  "content": {
                    "application/json": {
                      "example": [{"id": 1, "name": "Fluffy"}]
                    }
                  }
                }
              }
            }
          },
          "/pets/{petId}": {
            "get": {
              "summary": "Info for a specific pet",
              "responses": {
                "200": {
                  "description": "Expected response to a valid request",
                  "content": {
                    "application/json": {
                      "example": {"id": 1, "name": "Fluffy"}
                    }
                  }
                }
              }
            }
          }
        }
      }
      ''';

      final report = mock.importOpenApi(openApiJson);
      expect(report.totalEndpoints, equals(2));
      expect(report.title, equals('Pet Store API'));

      // Check routes registered in router
      expect(mock.router.routes.any((r) => r.pathPattern == '/pets'), isTrue);
      expect(mock.router.routes.any((r) => r.pathPattern == '/pets/:petId'),
          isTrue);

      mock.dispose();
    });
  });

  group('Custom Matchers & Assertions', () {
    test('verifies hasRequested matcher', () async {
      final mock = MockMate(delayProvider: const ZeroDelayProvider());
      mock.get('/api/ping', (req) => MockResponse.text('pong'));

      await mock.handleRequest(MockRequest(
          method: HttpMethod.get, uri: Uri.parse('http://localhost/api/ping')));

      expect(mock,
          hasRequested(path: '/api/ping', method: HttpMethod.get, count: 1));
      mock.dispose();
    });
  });
}
