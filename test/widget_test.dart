import 'package:flutter_test/flutter_test.dart';

import 'package:stock_facile/main.dart';

void main() {
  testWidgets('L\'application affiche le titre StockFacile', (tester) async {
    await tester.pumpWidget(const StockFacileApp());
    expect(find.text('StockFacile'), findsOneWidget);
  });
}
