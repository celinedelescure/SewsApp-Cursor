import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/profile/data/fabric_item.dart';
import 'package:sewsapp/features/profile/data/fabrics_repository.dart';
import 'package:sewsapp/features/profile/presentation/fabric_edit_screen.dart';

class _FakeFabricsSource implements FabricsSource {
  FabricItemInput? lastInput;

  @override
  Future<List<FabricItem>> fetchMyFabrics() async => const [];

  @override
  Future<FabricItem> addFabric(FabricItemInput input) async {
    lastInput = input;
    return FabricItem(
      id: 'f-new',
      userId: 'u1',
      name: input.name,
      type: input.type,
      color: input.color,
      length: input.length,
    );
  }
}

void main() {
  testWidgets('Ajout tissu valide pop avec le tissu créé', (tester) async {
    final fake = _FakeFabricsSource();
    FabricItem? popped;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<FabricItem>(
                  MaterialPageRoute(
                    builder: (_) => FabricEditScreen(source: fake),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jersey bleu');
    await tester.enterText(fields.at(2), 'bleu');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(fake.lastInput?.name, 'Jersey bleu');
    expect(fake.lastInput?.color, 'bleu');
    expect(popped?.name, 'Jersey bleu');
  });

  testWidgets('Nom vide refuse la soumission', (tester) async {
    final fake = _FakeFabricsSource();

    await tester.pumpWidget(
      MaterialApp(home: FabricEditScreen(source: fake)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Indiquez un nom.'), findsOneWidget);
    expect(fake.lastInput, isNull);
  });
}
