import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Initialise le client Supabase si URL + anon key sont fournis.
///
/// Sans config : l'app tourne en mode placeholder (UI navigable, pas d'API).
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (!Env.hasSupabaseConfig) {
      debugPrint(
        'Supabase non configuré — lancez avec '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
        '(ref prod hint: ${Env.supabaseProjectRefHint})',
      );
      return;
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      // Clé « anon » du dashboard = publishable key côté SDK.
      publishableKey: Env.supabaseAnonKey,
    );
    _initialized = true;
  }

  /// Client prêt uniquement après [init] réussi.
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase non initialisé. Fournissez SUPABASE_URL et SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }
}
