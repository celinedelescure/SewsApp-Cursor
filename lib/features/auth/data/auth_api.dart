import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_profile.dart';

/// Contrat auth utilisé par l'UI (facilite les tests widget).
abstract class AuthApi {
  Session? get currentSession;
  User? get currentUser;
  Stream<AuthState> get authStateChanges;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserProfile> fetchProfile(User user);
}
