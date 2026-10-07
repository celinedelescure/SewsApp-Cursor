import 'package:flutter/material.dart';

import '../../../core/roles/user_role.dart';
import '../../../shell/placeholder_page.dart';

/// Profil utilisateur — placeholder.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.role,
    this.onChangeRole,
  });

  final UserRole role;
  final VoidCallback? onChangeRole;

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Profil',
      subtitle: role.labelFr,
      body:
          'Compte, préférences et statut Stripe Connect (à venir). '
          'Auth Supabase non branchée dans ce scaffold.',
      icon: Icons.person_outline,
      action: onChangeRole == null
          ? null
          : FilledButton.tonal(
              onPressed: onChangeRole,
              child: const Text('Changer de rôle (démo)'),
            ),
    );
  }
}
