import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'feed_post.dart';

/// Erreur métier feed (messages FR pour l'UI).
class FeedFailure implements Exception {
  const FeedFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrat de lecture du fil (facilite les tests widget).
abstract class FeedSource {
  Future<List<FeedPost>> fetchPosts({String? typeFilter});
}

/// Lecture du fil `posts` (+ auteur via join `profiles`).
class FeedRepository implements FeedSource {
  FeedRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id,author_id,caption,image_url,images,likes_count,'
      'pattern_name,pattern_brand,category,type,created_at,'
      'author:profiles!author_id(username,display_name,avatar_url)';

  /// Charge les posts récents. [typeFilter] optionnel (ex. Dress, Top).
  @override
  Future<List<FeedPost>> fetchPosts({String? typeFilter}) async {
    try {
      final filter = typeFilter?.trim();
      final List<dynamic> rows;
      if (filter != null && filter.isNotEmpty && filter != 'Tous') {
        rows = await _client
            .from('posts')
            .select(_select)
            .eq('type', filter)
            .order('created_at', ascending: false)
            .limit(50);
      } else {
        rows = await _client
            .from('posts')
            .select(_select)
            .order('created_at', ascending: false)
            .limit(50);
      }

      return rows
          .map(
            (row) => FeedPost.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw FeedFailure(_mapPostgrest(e));
    } catch (_) {
      throw const FeedFailure(
        'Impossible de charger le fil. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  String _mapPostgrest(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501' || (e.message.toLowerCase().contains('permission'))) {
      return 'Accès refusé au fil d’actualité. Reconnectez-vous.';
    }
    if (code == 'PGRST116') {
      return 'Aucun post trouvé.';
    }
    return 'Erreur lors du chargement du fil.';
  }
}
