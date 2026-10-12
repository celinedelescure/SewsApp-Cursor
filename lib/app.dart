import 'package:flutter/material.dart';

import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/missing_config_screen.dart';

/// Racine SewsApp : auth Supabase puis shell selon le rôle du profil.
class SewsApp extends StatelessWidget {
  const SewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SewsApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SupabaseBootstrap.isInitialized
          ? AuthGate(repository: AuthRepository())
          : const MissingConfigScreen(),
    );
  }
}
