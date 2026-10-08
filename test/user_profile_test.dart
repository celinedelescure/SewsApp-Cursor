import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/roles/user_role.dart';
import 'package:sewsapp/features/auth/data/user_profile.dart';

void main() {
  test('UserProfile.fromMap lit account_type Designer', () {
    final profile = UserProfile.fromMap(
      {
        'id': 'abc',
        'username': 'marie',
        'display_name': 'Marie D.',
        'account_type': 'Designer',
      },
      email: 'marie@exemple.com',
    );

    expect(profile.role, UserRole.designer);
    expect(profile.displayLabel, 'Marie D.');
    expect(profile.email, 'marie@exemple.com');
  });

  test('fallback sans profil → couturière', () {
    final profile = UserProfile.fallback(id: 'x', email: 'a@b.c');
    expect(profile.role, UserRole.couturiere);
    expect(profile.displayLabel, 'a@b.c');
  });
}
