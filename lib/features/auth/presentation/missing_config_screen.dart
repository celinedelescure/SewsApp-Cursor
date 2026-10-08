import 'package:flutter/material.dart';

import '../../../core/config/env.dart';

/// Affiché quand SUPABASE_URL / SUPABASE_ANON_KEY manquent.
class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SewsApp',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Configuration manquante',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Pour vous connecter, relancez l’app avec l’URL et la clé '
                'anon Supabase (jamais la clé service_role).',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                'flutter run -d chrome \\\n'
                '  --dart-define=SUPABASE_URL=https://${Env.supabaseProjectRefHint}.supabase.co \\\n'
                '  --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Voir le README pour le détail (clé anon dans le dashboard '
                'Supabase → Project Settings → API).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
