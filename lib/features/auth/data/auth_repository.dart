import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'auth_api.dart';
import 'user_profile.dart';

/// Erreurs auth présentées à l'utilisateur (messages FR).
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Accès Auth + lecture `profiles` (clé anon uniquement).
class AuthRepository implements AuthApi {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    } catch (_) {
      throw const AuthFailure(
        'Connexion impossible. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    } catch (_) {
      throw const AuthFailure(
        'Inscription impossible. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    } catch (_) {
      throw const AuthFailure('Déconnexion impossible pour le moment.');
    }
  }

  /// Charge le profil ; en cas d'échec RLS / absence, retourne un fallback.
  @override
  Future<UserProfile> fetchProfile(User user) async {
    try {
      final row = await _client
          .from('profiles')
          .select('id, username, display_name, account_type')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        return UserProfile.fallback(id: user.id, email: user.email);
      }
      return UserProfile.fromMap(row, email: user.email);
    } catch (_) {
      return UserProfile.fallback(id: user.id, email: user.email);
    }
  }

  String _mapAuthError(AuthException e) {
    final raw = e.message.toLowerCase();
    final code = (e.code ?? '').toLowerCase();
    if (raw.contains('invalid login credentials') ||
        raw.contains('invalid_credentials') ||
        code == 'invalid_credentials') {
      return 'E-mail ou mot de passe incorrect.';
    }
    if (raw.contains('email not confirmed')) {
      return 'Confirmez votre e-mail avant de vous connecter '
          '(lien reçu dans votre boîte mail).';
    }
    if (raw.contains('user already registered') ||
        raw.contains('already been registered')) {
      return 'Un compte existe déjà avec cet e-mail.';
    }
    if (raw.contains('password') &&
        (raw.contains('weak') ||
            raw.contains('least') ||
            raw.contains('short'))) {
      return 'Mot de passe trop court (6 caractères minimum).';
    }
    if (raw.contains('rate limit') || raw.contains('too many')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    if (raw.contains('signup') && raw.contains('disabled')) {
      return 'Les inscriptions sont désactivées pour le moment.';
    }
    if (e.statusCode == '400' || e.statusCode == '401') {
      return 'Identifiants invalides. Vérifiez e-mail et mot de passe.';
    }
    return 'Erreur : ${e.message}';
  }
}
