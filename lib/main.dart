import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.init();
  runApp(const SewsApp());
}
