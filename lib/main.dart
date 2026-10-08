import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Expose la sémantique web pour clics / accessibilité (CanvasKit).
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  await SupabaseBootstrap.init();
  runApp(const SewsApp());
}
