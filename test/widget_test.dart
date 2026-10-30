import 'package:flutter_test/flutter_test.dart';

import 'package:stock_facile/main.dart';

void main() {
  testWidgets('L\'application affiche l\'écran de test', (tester) async {
    await tester.pumpWidget(const StockFacileApp());
    expect(find.text('StockFacile – Tests'), findsOneWidget);
    expect(find.text('Ouvrir la base'), findsOneWidget);
  });
}
