import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/supabase/supabase_client.dart';

/// Résultat d’une tentative de checkout Stripe Connect.
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Redirection Checkout OK — [url] à ouvrir (navigateur / onglet).
class CheckoutRedirect extends CheckoutResult {
  const CheckoutRedirect({
    required this.url,
    this.sessionId,
    this.connectMode,
    this.commissionPercent,
  });

  final String url;
  final String? sessionId;
  final String? connectMode;
  final num? commissionPercent;
}

/// Secrets Stripe / fonction absents → UI mode test (pas de faux achat en base).
class CheckoutUnavailable extends CheckoutResult {
  const CheckoutUnavailable(this.message, {this.code});

  final String message;
  final String? code;
}

/// Erreur métier (déjà possédé, session, etc.).
class CheckoutFailure extends CheckoutResult {
  const CheckoutFailure(this.message, {this.code});

  final String message;
  final String? code;
}

/// Contrat checkout (tests / injection) — jamais de secret Stripe côté app.
abstract class PatternCheckout {
  Future<CheckoutResult> createCheckoutSession({
    required String patternId,
    String? successUrl,
    String? cancelUrl,
  });

  Future<bool> openCheckoutUrl(String url);
}

/// Ouvre une Checkout Session via Edge Function (jamais de secret Stripe côté app).
class StripeCheckoutService implements PatternCheckout {
  StripeCheckoutService({
    SupabaseClient? client,
    Future<bool> Function(Uri url, {LaunchMode mode})? launchUrlFn,
  })  : _client = client ?? SupabaseBootstrap.client,
        _launchUrl = launchUrlFn ?? launchUrl;

  final SupabaseClient _client;
  final Future<bool> Function(Uri url, {LaunchMode mode}) _launchUrl;

  static const functionName = 'create-checkout-session';

  /// Appelle l’Edge Function puis retourne l’URL Checkout (ou un état FR).
  @override
  Future<CheckoutResult> createCheckoutSession({
    required String patternId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const CheckoutFailure(
        'Connectez-vous pour acheter un patron.',
        code: 'unauthorized',
      );
    }

    final body = <String, dynamic>{
      'pattern_id': patternId,
      if (successUrl != null && successUrl.isNotEmpty) 'success_url': successUrl,
      if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancel_url': cancelUrl,
    };

    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );

      final data = _asMap(response.data);
      final status = response.status;

      if (status == 503 || data['code'] == 'stripe_not_configured') {
        return CheckoutUnavailable(
          data['error'] as String? ??
              'Paiement Stripe non configuré côté serveur (clé test manquante).',
          code: 'stripe_not_configured',
        );
      }

      if (status == 404) {
        return const CheckoutUnavailable(
          'La fonction de paiement n’est pas encore déployée sur Supabase.',
          code: 'function_not_deployed',
        );
      }

      if (status >= 400) {
        return CheckoutFailure(
          data['error'] as String? ??
              'Impossible de démarrer le paiement. Réessayez.',
          code: data['code'] as String?,
        );
      }

      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        return const CheckoutFailure(
          'Aucune URL de paiement reçue.',
          code: 'no_url',
        );
      }

      return CheckoutRedirect(
        url: url,
        sessionId: data['session_id'] as String?,
        connectMode: data['connect_mode'] as String?,
        commissionPercent: data['commission_percent'] as num?,
      );
    } on FunctionException catch (e) {
      return _mapFunctionException(e);
    } catch (_) {
      return const CheckoutFailure(
        'Erreur réseau lors du paiement. Vérifiez votre connexion.',
        code: 'network',
      );
    }
  }

  /// Ouvre l’URL Checkout dans le navigateur externe.
  @override
  Future<bool> openCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return _launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  CheckoutResult _mapFunctionException(FunctionException e) {
    final details = e.details;
    final map = details is Map
        ? Map<String, dynamic>.from(details)
        : <String, dynamic>{};
    final code = map['code'] as String? ?? e.reasonPhrase;
    final message = map['error'] as String? ?? e.reasonPhrase ?? e.toString();

    if (e.status == 503 ||
        code == 'stripe_not_configured' ||
        message.toLowerCase().contains('stripe')) {
      return CheckoutUnavailable(
        message.isNotEmpty
            ? message
            : 'Stripe non configuré (secrets Edge Function manquants).',
        code: code ?? 'stripe_not_configured',
      );
    }

    if (e.status == 404) {
      return CheckoutUnavailable(
        'La fonction de paiement n’est pas encore déployée sur Supabase.',
        code: 'function_not_deployed',
      );
    }

    return CheckoutFailure(
      message.isNotEmpty
          ? message
          : 'Impossible de démarrer le paiement. Réessayez.',
      code: code,
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
