import '../../../core/roles/user_role.dart';

/// Profil applicatif (table `profiles`).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.username,
    this.displayName,
    this.accountType,
    this.email,
  });

  final String id;
  final UserRole role;
  final String? username;
  final String? displayName;
  final String? accountType;
  final String? email;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail;
    return 'Compte SewsApp';
  }

  factory UserProfile.fromMap(
    Map<String, dynamic> map, {
    String? email,
  }) {
    final accountType = map['account_type'] as String?;
    return UserProfile(
      id: map['id'] as String,
      role: UserRoleX.fromAccountType(accountType),
      username: map['username'] as String?,
      displayName: map['display_name'] as String?,
      accountType: accountType,
      email: email,
    );
  }

  /// Profil minimal si la ligne `profiles` est absente / inaccessible.
  factory UserProfile.fallback({
    required String id,
    String? email,
  }) {
    return UserProfile(
      id: id,
      role: UserRole.couturiere,
      email: email,
      accountType: 'Regular User',
    );
  }
}
