/// Runtime configuration via `--dart-define` (preferred) or defaults.
///
/// Example:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
/// ```
///
/// Never commit real secrets. See `.env.example`.
class Env {
  Env._();

  static const _rawSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Projet Supabase production (données utilisateurs).
  static const supabaseProjectRefHint = 'uwszstlhdrkxznygdloe';

  /// URL racine du projet (sans `/rest/v1` ni slash final).
  ///
  /// Certains secrets injectés pointent vers PostgREST ; Auth a besoin de la
  /// racine `https://<ref>.supabase.co`.
  static String get supabaseUrl => normalizeSupabaseUrl(_rawSupabaseUrl);

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String normalizeSupabaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    const restSuffix = '/rest/v1';
    if (url.toLowerCase().endsWith(restSuffix)) {
      url = url.substring(0, url.length - restSuffix.length);
    }
    return url;
  }
}
