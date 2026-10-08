import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/config/env.dart';

void main() {
  test('normalizeSupabaseUrl retire /rest/v1 et les slashs finaux', () {
    expect(
      Env.normalizeSupabaseUrl(
        'https://uwszstlhdrkxznygdloe.supabase.co/rest/v1',
      ),
      'https://uwszstlhdrkxznygdloe.supabase.co',
    );
    expect(
      Env.normalizeSupabaseUrl(
        'https://uwszstlhdrkxznygdloe.supabase.co/rest/v1/',
      ),
      'https://uwszstlhdrkxznygdloe.supabase.co',
    );
    expect(
      Env.normalizeSupabaseUrl('https://uwszstlhdrkxznygdloe.supabase.co/'),
      'https://uwszstlhdrkxznygdloe.supabase.co',
    );
  });
}
