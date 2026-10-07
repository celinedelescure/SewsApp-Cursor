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

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Production data lives in this project (migration later). Scaffold only.
  static const supabaseProjectRefHint = 'pbeyfeepdrlfjxanvvwa';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
