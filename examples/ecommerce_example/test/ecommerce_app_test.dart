import 'package:ecommerce_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockmate/mockmate.dart';

void main() {
  testWidgets('Ecommerce example loads products from stateful MockMate backend',
      (tester) async {
    final mockMate = MockMate(delayProvider: const ZeroDelayProvider());
    mockMate.resource(
      '/api/products',
      initialData: [
        {
          'id': 1,
          'name': 'MockMate Pro Headset',
          'category': 'Audio',
          'price': 120.0,
          'stock': 15,
          'description': 'Great mock item.',
        },
      ],
    );

    await tester.pumpWidget(MockMateEcommerceApp(mockMate: mockMate));
    await tester.pumpAndSettle();

    expect(find.text('MockMate Ecommerce Store'), findsOneWidget);
    expect(find.text('MockMate Pro Headset'), findsOneWidget);
    expect(find.text('\$120.00'), findsOneWidget);

    mockMate.dispose();
  });
}
