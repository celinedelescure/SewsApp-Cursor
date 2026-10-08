import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import 'fabric_item.dart';

/// Erreur métier stock tissus (messages FR).
class FabricsFailure implements Exception {
  const FabricsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrat lecture / écriture stock tissus (tests widget).
abstract class FabricsSource {
  Future<List<FabricItem>> fetchMyFabrics();

  Future<FabricItem> addFabric(FabricItemInput input);
}

/// Accès Supabase table `fabrics` (stock couturière en prod).
///
/// Note : le projet vide sandbox utilisait `fabric_stash` ; la prod
/// `uwsz…` expose `fabrics` (+ jsonb `profiles.fabric_stash` non utilisé ici).
class FabricsRepository implements FabricsSource {
  FabricsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id,user_id,name,type,weave,weight,stretch,color,pattern,'
      'length,width,image_url,notes,created_at';

  @override
  Future<List<FabricItem>> fetchMyFabrics() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    try {
      final rows = await _client
          .from('fabrics')
          .select(_select)
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      return (rows as List<dynamic>)
          .map(
            (row) =>
                FabricItem.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .where((f) => f.id.isNotEmpty)
          .toList();
    } on PostgrestException catch (e) {
      throw FabricsFailure(_mapPostgrest(e, reading: true));
    } catch (_) {
      throw const FabricsFailure(
        'Impossible de charger vos tissus. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  @override
  Future<FabricItem> addFabric(FabricItemInput input) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const FabricsFailure(
        'Vous devez être connecté pour ajouter un tissu.',
      );
    }

    final name = input.name.trim();
    if (name.isEmpty) {
      throw const FabricsFailure('Indiquez un nom pour le tissu.');
    }

    String? opt(String? v) {
      final t = v?.trim();
      if (t == null || t.isEmpty) return null;
      return t;
    }

    final payload = <String, dynamic>{
      'user_id': user.id,
      'name': name,
      if (opt(input.type) != null) 'type': opt(input.type),
      if (opt(input.color) != null) 'color': opt(input.color),
      if (opt(input.weave) != null) 'weave': opt(input.weave),
      if (opt(input.weight) != null) 'weight': opt(input.weight),
      if (opt(input.stretch) != null) 'stretch': opt(input.stretch),
      if (opt(input.notes) != null) 'notes': opt(input.notes),
      if (opt(input.imageUrl) != null) 'image_url': opt(input.imageUrl),
      if (input.length != null) 'length': input.length,
      if (input.width != null) 'width': input.width,
    };

    try {
      final row = await _client
          .from('fabrics')
          .insert(payload)
          .select(_select)
          .single();
      return FabricItem.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw FabricsFailure(_mapPostgrest(e, reading: false));
    } catch (e) {
      if (e is FabricsFailure) rethrow;
      throw const FabricsFailure(
        'Impossible d’enregistrer le tissu. Vérifiez votre réseau et réessayez.',
      );
    }
  }

  String _mapPostgrest(PostgrestException e, {required bool reading}) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == '42501' || msg.contains('permission') || msg.contains('policy')) {
      return reading
          ? 'Accès refusé à votre stock tissus. Reconnectez-vous.'
          : 'Enregistrement refusé (droits insuffisants). Reconnectez-vous.';
    }
    if (code == '23502') {
      return 'Certains champs obligatoires manquent. Vérifiez le formulaire.';
    }
    if (code == 'PGRST116') {
      return reading
          ? 'Tissu introuvable.'
          : 'Enregistrement impossible — aucune ligne renvoyée.';
    }
    return reading
        ? 'Impossible de charger vos tissus. Réessayez.'
        : 'Impossible d’enregistrer le tissu. Réessayez.';
  }
}
