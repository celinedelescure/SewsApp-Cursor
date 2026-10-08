import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'pattern_listing.dart';
import 'pattern_purchase.dart';

/// Erreur métier patrons (messages FR pour l'UI).
class PatternsFailure implements Exception {
  const PatternsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrat lecture / écriture patrons (facilite les tests widget).
abstract class PatternsSource {
  Future<List<PatternListing>> fetchPublishedCatalog({String? typeFilter});

  Future<List<PatternListing>> fetchDesignerPatterns(String authorId);

  Future<PatternListing> fetchById(String id);

  Future<PatternListing> createPattern(PatternListingInput input);

  Future<PatternListing> updatePattern(String id, PatternListingInput input);

  /// Achats de l’utilisateur connecté (RLS : souvent seulement les siens).
  Future<List<PatternPurchase>> fetchMyPurchases();

  /// IDs issus de `profiles.purchased_pattern_ids` (dénormalisé).
  Future<Set<String>> fetchPurchasedPatternIds();
}

/// Accès Supabase `patterns` + `purchases` (clé anon + session).
class PatternsRepository implements PatternsSource {
  PatternsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id,author_id,name,description,price,currency,brand,category,type,'
      'cover_image,images,is_published,is_draft,archived,sales_count,'
      'difficulty,created_at,'
      'author:profiles!author_id(username,display_name)';

  static const _purchaseSelect =
      'id,user_id,pattern_id,pattern_name,brand,price_paid,currency,'
      'purchased_at,cover_image';

  @override
  Future<List<PatternListing>> fetchPublishedCatalog({String? typeFilter}) async {
    try {
      final filter = typeFilter?.trim();
      var query = _client
          .from('patterns')
          .select(_select)
          .eq('is_published', true)
          .eq('is_draft', false)
          .eq('archived', false);

      if (filter != null && filter.isNotEmpty && filter != 'Tous') {
        query = query.eq('type', filter);
      }

      final rows = await query.order('created_at', ascending: false).limit(50);

      return (rows as List<dynamic>)
          .map(
            (row) =>
                PatternListing.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw PatternsFailure(_mapPostgrest(e, reading: true));
    } catch (_) {
      throw const PatternsFailure(
        'Impossible de charger les patrons. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<List<PatternListing>> fetchDesignerPatterns(String authorId) async {
    try {
      final rows = await _client
          .from('patterns')
          .select(_select)
          .eq('author_id', authorId)
          .order('created_at', ascending: false)
          .limit(100);

      return (rows as List<dynamic>)
          .map(
            (row) =>
                PatternListing.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw PatternsFailure(_mapPostgrest(e, reading: true));
    } catch (_) {
      throw const PatternsFailure(
        'Impossible de charger vos patrons. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<PatternListing> fetchById(String id) async {
    try {
      final row = await _client
          .from('patterns')
          .select(_select)
          .eq('id', id)
          .maybeSingle();

      if (row == null) {
        throw const PatternsFailure('Patron introuvable.');
      }
      return PatternListing.fromMap(Map<String, dynamic>.from(row));
    } on PatternsFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw PatternsFailure(_mapPostgrest(e, reading: true));
    } catch (_) {
      throw const PatternsFailure(
        'Impossible de charger ce patron. Réessayez.',
      );
    }
  }

  @override
  Future<PatternListing> createPattern(PatternListingInput input) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const PatternsFailure(
        'Vous devez être connecté pour créer un patron.',
      );
    }

    final name = input.name.trim();
    if (name.isEmpty) {
      throw const PatternsFailure('Indiquez un nom pour le patron.');
    }
    if (input.price < 0) {
      throw const PatternsFailure('Le prix ne peut pas être négatif.');
    }

    final cover = input.coverImageUrl?.trim();
    final hasCover = cover != null && cover.isNotEmpty;
    final type = input.type?.trim();
    final description = input.description.trim();

    final payload = <String, dynamic>{
      'author_id': user.id,
      'name': name,
      'price': input.price,
      'currency': 'EUR',
      'category': 'Women',
      'description': description.isEmpty ? null : description,
      'is_published': input.isPublished,
      'is_draft': !input.isPublished,
      'archived': false,
      if (type != null && type.isNotEmpty && type != 'Tous') 'type': type,
      if (hasCover) 'cover_image': cover,
      if (hasCover) 'images': [cover],
    };

    try {
      final row = await _client
          .from('patterns')
          .insert(payload)
          .select(_select)
          .single();
      return PatternListing.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw PatternsFailure(_mapPostgrest(e, reading: false));
    } catch (e) {
      if (e is PatternsFailure) rethrow;
      throw const PatternsFailure(
        'Impossible d’enregistrer le patron. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<PatternListing> updatePattern(
    String id,
    PatternListingInput input,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const PatternsFailure(
        'Vous devez être connecté pour modifier un patron.',
      );
    }

    final name = input.name.trim();
    if (name.isEmpty) {
      throw const PatternsFailure('Indiquez un nom pour le patron.');
    }
    if (input.price < 0) {
      throw const PatternsFailure('Le prix ne peut pas être négatif.');
    }

    final cover = input.coverImageUrl?.trim();
    final hasCover = cover != null && cover.isNotEmpty;
    final type = input.type?.trim();
    final description = input.description.trim();

    final payload = <String, dynamic>{
      'name': name,
      'price': input.price,
      'description': description.isEmpty ? null : description,
      'is_published': input.isPublished,
      'is_draft': !input.isPublished,
      if (type != null && type.isNotEmpty && type != 'Tous') 'type': type,
      if (hasCover) 'cover_image': cover,
      if (hasCover) 'images': [cover],
    };

    try {
      final row = await _client
          .from('patterns')
          .update(payload)
          .eq('id', id)
          .eq('author_id', user.id)
          .select(_select)
          .maybeSingle();

      if (row == null) {
        throw const PatternsFailure(
          'Modification refusée : patron introuvable ou non autorisé.',
        );
      }
      return PatternListing.fromMap(Map<String, dynamic>.from(row));
    } on PatternsFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw PatternsFailure(_mapPostgrest(e, reading: false));
    } catch (_) {
      throw const PatternsFailure(
        'Impossible de modifier le patron. Réessayez.',
      );
    }
  }

  @override
  Future<List<PatternPurchase>> fetchMyPurchases() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    try {
      final rows = await _client
          .from('purchases')
          .select(_purchaseSelect)
          .eq('user_id', user.id)
          .order('purchased_at', ascending: false)
          .limit(50);

      return (rows as List<dynamic>)
          .map(
            (row) =>
                PatternPurchase.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .where((p) => p.patternId.isNotEmpty)
          .toList();
    } on PostgrestException {
      // RLS peut masquer les achats — ne pas bloquer le catalogue.
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Set<String>> fetchPurchasedPatternIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final fromPurchases = <String>{};
    try {
      final purchases = await fetchMyPurchases();
      for (final p in purchases) {
        if (p.patternId.isNotEmpty) fromPurchases.add(p.patternId);
      }
    } catch (_) {
      // ignore
    }

    try {
      final row = await _client
          .from('profiles')
          .select('purchased_pattern_ids')
          .eq('id', user.id)
          .maybeSingle();
      final raw = row?['purchased_pattern_ids'];
      if (raw is List) {
        for (final item in raw) {
          if (item is String && item.trim().isNotEmpty) {
            fromPurchases.add(item.trim());
          }
        }
      }
    } catch (_) {
      // ignore — dénormalisé optionnel
    }

    return fromPurchases;
  }

  String _mapPostgrest(PostgrestException e, {required bool reading}) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == '42501' || msg.contains('permission') || msg.contains('policy')) {
      return reading
          ? 'Accès refusé aux patrons. Reconnectez-vous.'
          : 'Enregistrement refusé (droits insuffisants). '
              'Compte Designer requis, ou reconnectez-vous.';
    }
    if (code == '23503') {
      return 'Profil introuvable pour ce compte. Reconnectez-vous.';
    }
    if (code == '23502') {
      return 'Certains champs obligatoires manquent. Vérifiez le formulaire.';
    }
    if (code == 'PGRST116') {
      return 'Patron introuvable.';
    }
    return reading
        ? 'Erreur lors du chargement des patrons.'
        : 'Erreur lors de l’enregistrement du patron.';
  }
}
