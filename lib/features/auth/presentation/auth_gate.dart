import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shell/app_shell.dart';
import '../data/auth_repository.dart';
import '../data/user_profile.dart';
import 'login_screen.dart';

/// Restaure la session au démarrage et bascule login ↔ shell.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.repository,
  });

  final AuthRepository repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSub;
  final GlobalKey<NavigatorState> _authNavKey = GlobalKey<NavigatorState>();

  bool _booting = true;
  bool _loadingProfile = false;
  UserProfile? _profile;
  String? _profileError;
  String? _sessionUserId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = widget.repository.currentSession;
    if (session != null) {
      _sessionUserId = session.user.id;
      await _loadProfile(session.user);
    }
    if (!mounted) return;
    setState(() => _booting = false);

    _authSub = widget.repository.authStateChanges.listen((data) async {
      final session = data.session;
      if (session == null) {
        // Déjà déconnecté : ne pas setState (sinon remount login →
        // perte des erreurs FR et de la pile « Créer un compte »).
        if (_sessionUserId == null && _profile == null && !_loadingProfile) {
          return;
        }
        if (!mounted) return;
        setState(() {
          _sessionUserId = null;
          _profile = null;
          _profileError = null;
          _loadingProfile = false;
        });
        return;
      }

      final sameUser = _sessionUserId == session.user.id && _profile != null;
      if (sameUser && data.event == AuthChangeEvent.tokenRefreshed) {
        return;
      }

      _sessionUserId = session.user.id;
      await _loadProfile(session.user);
    });
  }

  Future<void> _loadProfile(User user) async {
    if (!mounted) return;
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await widget.repository.fetchProfile(user);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = UserProfile.fallback(id: user.id, email: user.email);
        _profileError =
            'Profil introuvable — rôle Couturière utilisé par défaut.';
        _loadingProfile = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await widget.repository.signOut();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_booting || (_loadingProfile && _profile == null)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement…'),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      // Navigator dédié : conserve login/signup même si AuthGate rebuild.
      return Navigator(
        key: _authNavKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => LoginScreen(repository: widget.repository),
          );
        },
      );
    }

    return AppShell(
      role: profile.role,
      profile: profile,
      profileNotice: _profileError,
      onLogout: _logout,
    );
  }
}
