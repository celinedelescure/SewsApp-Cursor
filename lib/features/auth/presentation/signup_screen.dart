import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../data/auth_repository.dart';

/// Inscription e-mail / mot de passe (si Auth l'autorise côté projet).
class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.repository,
  });

  final AuthApi repository;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final response = await widget.repository.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session != null) {
        // Session active → AuthGate bascule ; on ferme l'écran d'inscription.
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _info =
            'Compte créé. Si la confirmation e-mail est activée, '
            'ouvrez le lien reçu puis reconnectez-vous.';
      });
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Text(
                  'Inscrivez-vous avec votre e-mail. '
                  'Le rôle par défaut est Couturière '
                  '(modifiable plus tard dans le profil).',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Saisissez votre e-mail.';
                          if (!v.contains('@')) return 'E-mail invalide.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          helperText: 'Au moins 6 caractères',
                          suffixIcon: IconButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.length < 6) {
                            return 'Mot de passe trop court (6 min).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        enabled: !_loading,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _Banner(
                          text: _error!,
                          background: theme.colorScheme.errorContainer,
                          foreground: theme.colorScheme.onErrorContainer,
                        ),
                      ],
                      if (_info != null) ...[
                        const SizedBox(height: 16),
                        _Banner(
                          text: _info!,
                          background: theme.colorScheme.primaryContainer,
                          foreground: theme.colorScheme.onPrimaryContainer,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Créer mon compte'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
              ),
        ),
      ),
    );
  }
}
