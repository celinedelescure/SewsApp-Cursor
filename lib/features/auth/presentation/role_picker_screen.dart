import 'package:flutter/material.dart';

import '../../../core/config/env.dart';
import '../../../core/roles/user_role.dart';
import '../../../core/supabase/supabase_client.dart';

/// Écran temporaire : choisir un rôle pour explorer le shell (pas d'auth réelle).
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key, required this.onRoleSelected});

  final ValueChanged<UserRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            Text(
              'SewsApp',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rebuild Flutter — choisissez un rôle pour naviguer dans le shell.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _ConfigBanner(
              supabaseReady: SupabaseBootstrap.isInitialized,
            ),
            const SizedBox(height: 28),
            for (final role in UserRole.values) ...[
              _RoleCard(
                role: role,
                onTap: () => onRoleSelected(role),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfigBanner extends StatelessWidget {
  const _ConfigBanner({required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = supabaseReady
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final onColor = supabaseReady
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          supabaseReady
              ? 'Supabase connecté (stub client prêt).'
              : 'Mode placeholder — pas de secrets. '
                  'Ajoutez SUPABASE_URL / SUPABASE_ANON_KEY via --dart-define '
                  '(ref prod : ${Env.supabaseProjectRefHint}).',
          style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onTap});

  final UserRole role;
  final VoidCallback onTap;

  IconData get _icon => switch (role) {
        UserRole.couturiere => Icons.auto_awesome_mosaic_outlined,
        UserRole.designer => Icons.design_services_outlined,
        UserRole.marchandTissus => Icons.storefront_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(_icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.labelFr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.descriptionFr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
