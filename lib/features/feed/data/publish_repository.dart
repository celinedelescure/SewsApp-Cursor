import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'feed_post.dart';
import 'feed_repository.dart';

/// Données du formulaire « Publier un projet » → colonnes réelles `posts`.
class PublishProjectInput {
  const PublishProjectInput({
    required this.title,
    this.caption = '',
    this.description = '',
    this.type,
    this.imageUrl,
  });

  /// → `pattern_name` (titre affiché dans le feed si caption vide).
  final String title;

  /// → `caption`
  final String caption;

  /// → `modifications` (pas de colonne `description` en prod).
  final String description;

  /// → `type` (Dress, Top, …)
  final String? type;

  /// → `image_url` (+ `images[]`)
  final String? imageUrl;
}

/// Contrat publication (tests widget).
abstract class PublishSource {
  Future<FeedPost> createPost(PublishProjectInput input);

  /// Upload optionnel vers Storage. Retourne l’URL publique, ou `null`
  /// si le bucket / RLS refuse (l’UI bascule sur le champ URL).
  Future<String?> uploadPostImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });
}

/// Insert `posts` + upload image (anon + session utilisateur).
class PublishRepository implements PublishSource {
  PublishRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  /// Bucket prod réel (préfixe `posts/`). Pas de bucket séparé nommé `posts`.
  static const storageBucket = 'sewsapp-images';
  static const storagePrefix = 'posts';

  static const _select =
      'id,author_id,caption,image_url,images,likes_count,'
      'pattern_name,pattern_brand,category,type,created_at,'
      'author:profiles!author_id(username,display_name,avatar_url)';

  @override
  Future<FeedPost> createPost(PublishProjectInput input) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const FeedFailure(
        'Vous devez être connecté pour publier un projet.',
      );
    }

    final title = input.title.trim();
    final caption = input.caption.trim();
    final description = input.description.trim();
    if (title.isEmpty && caption.isEmpty) {
      throw const FeedFailure(
        'Indiquez au moins un titre ou une légende.',
      );
    }

    final imageUrl = input.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final type = input.type?.trim();

    final payload = <String, dynamic>{
      'author_id': user.id,
      'pattern_name': title.isEmpty ? null : title,
      'caption': caption,
      'modifications': description.isEmpty ? null : description,
      'category': 'Women',
      if (type != null && type.isNotEmpty && type != 'Tous') 'type': type,
      if (hasImage) 'image_url': imageUrl,
      if (hasImage) 'images': [imageUrl],
    };

    try {
      final row = await _client
          .from('posts')
          .insert(payload)
          .select(_select)
          .single();

      return FeedPost.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw FeedFailure(_mapPostgrest(e));
    } catch (e) {
      if (e is FeedFailure) rethrow;
      throw const FeedFailure(
        'Impossible de publier. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<String?> uploadPostImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$storagePrefix/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await _client.storage.from(storageBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
      return _client.storage.from(storageBucket).getPublicUrl(path);
    } on StorageException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String _mapPostgrest(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == '42501' || msg.contains('permission') || msg.contains('policy')) {
      return 'Publication refusée (droits insuffisants). '
          'Reconnectez-vous ou contactez le support.';
    }
    if (code == '23503') {
      return 'Profil introuvable pour ce compte. Reconnectez-vous.';
    }
    if (code == '23502') {
      return 'Certains champs obligatoires manquent. Vérifiez le formulaire.';
    }
    return 'Erreur lors de la publication.';
  }
}
