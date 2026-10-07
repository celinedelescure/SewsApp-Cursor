import 'package:flutter/material.dart';

import 'core/roles/user_role.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/role_picker_screen.dart';
import 'shell/app_shell.dart';

/// Racine SewsApp : sélection de rôle (démo) puis shell navigable.
class SewsApp extends StatefulWidget {
  const SewsApp({super.key});

  @override
  State<SewsApp> createState() => _SewsAppState();
}

class _SewsAppState extends State<SewsApp> {
  UserRole? _role;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SewsApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _role == null
          ? RolePickerScreen(
              onRoleSelected: (role) => setState(() => _role = role),
            )
          : AppShell(
              role: _role!,
              onChangeRole: () => setState(() => _role = null),
            ),
    );
  }
}
