import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/auth/data/auth_api.dart';
import 'package:sewsapp/features/auth/data/auth_repository.dart';
import 'package:sewsapp/features/auth/data/user_profile.dart';
import 'package:sewsapp/features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.signInError});

  final AuthFailure? signInError;
  var signInCalls = 0;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    final error = signInError;
    if (error != null) throw error;
    throw const AuthFailure('non atteint');
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfile> fetchProfile(User user) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('affiche une erreur FR après échec de connexion', (tester) async {
    final api = _FakeAuthApi(
      signInError: const AuthFailure('E-mail ou mot de passe incorrect.'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(repository: api),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(api.signInCalls, 1);
    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets('ouvre l’écran Créer un compte', (tester) async {
    final api = _FakeAuthApi();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(repository: api),
      ),
    );

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.textContaining('Inscrivez-vous'), findsOneWidget);
  });
}
