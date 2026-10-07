import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/app.dart';

void main() {
  testWidgets('affiche le sélecteur de rôle SewsApp', (tester) async {
    await tester.pumpWidget(const SewsApp());

    expect(find.text('SewsApp'), findsOneWidget);
    expect(find.text('Couturière'), findsOneWidget);
    expect(find.text('Designer'), findsOneWidget);
    expect(find.text('Marchand de tissus'), findsOneWidget);
  });

  testWidgets('navigue vers le shell couturière', (tester) async {
    await tester.pumpWidget(const SewsApp());
    await tester.tap(find.text('Couturière'));
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsWidgets);
    expect(find.text('Stock'), findsOneWidget);
  });
}
