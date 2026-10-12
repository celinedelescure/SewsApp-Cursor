import 'package:flutter/material.dart';

import '../../../core/roles/user_role.dart';
import '../../auth/data/user_profile.dart';

/// Profil utilisateur — rôle depuis `profiles` + déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.role,
    this.profile,
    this.profileNotice,
    this.onLogout,
  });

  final UserRole role;
  final UserProfile? profile;
  final String? profileNotice;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile?.displayLabel ?? role.labelFr;
    final accountType = profile?.accountType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.person_outline,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rôle : ${role.labelFr}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (accountType != null) ...[
            const SizedBox(height: 4),
            Text(
              'account_type : $accountType',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (profile?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              profile!.email!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (profileNotice != null) ...[
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  profileNotice!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Compte, préférences et Stripe Connect arriveront dans une '
            'prochaine version. Vous êtes bien connectée à Supabase.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onLogout != null) ...[
            const SizedBox(height: 32),
            Center(
              child: FilledButton.tonal(
                onPressed: () => onLogout!(),
                child: const Text('Se déconnecter'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
