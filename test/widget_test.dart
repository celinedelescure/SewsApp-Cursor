import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/app.dart';
import 'package:sewsapp/core/roles/user_role.dart';

void main() {
  testWidgets('sans dart-define : écran configuration manquante', (tester) async {
    await tester.pumpWidget(const SewsApp());

    expect(find.text('SewsApp'), findsOneWidget);
    expect(find.text('Configuration manquante'), findsOneWidget);
    expect(find.textContaining('SUPABASE_ANON_KEY'), findsOneWidget);
  });

  test('mappe account_type prod vers UserRole', () {
    expect(UserRoleX.fromAccountType('Regular User'), UserRole.couturiere);
    expect(UserRoleX.fromAccountType('Designer'), UserRole.designer);
    expect(UserRoleX.fromAccountType('Seller'), UserRole.marchandTissus);
    expect(UserRoleX.fromAccountType(null), UserRole.couturiere);
    expect(UserRoleX.fromAccountType('inconnu'), UserRole.couturiere);
  });
}

// Env normalize tested in env_test.dart

