import 'package:flutter/material.dart';

import '../../../core/roles/user_role.dart';
import '../data/feed_post.dart';
import '../data/feed_repository.dart';
import 'post_card.dart';

/// Fil d'actualité — posts Supabase (projets cousus).
class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    required this.role,
    this.source,
  });

  final UserRole role;
  final FeedSource? source;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final FeedSource _source = widget.source ?? FeedRepository();

  bool _loading = true;
  String? _error;
  List<FeedPost> _posts = const [];
  String _typeFilter = 'Tous';

  static const _typeOptions = <String>[
    'Tous',
    'Dress',
    'Top',
    'Skirt',
    'Coat',
    'Knitwear',
    'Intimwear',
    'Shirt',
    'Trousers',
    'Shorts',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _source.fetchPosts(
        typeFilter: _typeFilter == 'Tous' ? null : _typeFilter,
      );
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } on FeedFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible de charger le fil. Vérifiez votre réseau et réessayez.';
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() => _load();

  void _onFilterSelected(String value) {
    if (value == _typeFilter) return;
    setState(() => _typeFilter = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _typeOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final label = _typeOptions[index];
                final selected = label == _typeFilter;
                return FilterChip(
                  label: Text(label == 'Tous' ? 'Tous' : _labelFr(label)),
                  selected: selected,
                  onSelected: (_) => _onFilterSelected(label),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du fil…'),
          ],
        ),
      );
    }

    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Oups, une erreur est survenue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dynamic_feed_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun post pour le moment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _typeFilter == 'Tous'
                            ? 'Le fil d’actualité est vide. Tirez pour actualiser.'
                            : 'Aucun post pour ce filtre. Essayez « Tous ».',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: _posts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Créations et inspiration · ${widget.role.labelFr}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return PostCard(post: _posts[index - 1]);
        },
      ),
    );
  }

  String _labelFr(String type) {
    switch (type) {
      case 'Dress':
        return 'Robes';
      case 'Top':
        return 'Hauts';
      case 'Shirt':
        return 'Chemises';
      case 'Skirt':
        return 'Jupes';
      case 'Trousers':
        return 'Pantalons';
      case 'Shorts':
        return 'Shorts';
      case 'Coat':
        return 'Manteaux';
      case 'Knitwear':
        return 'Maille';
      case 'Intimwear':
        return 'Lingerie';
      default:
        return type;
    }
  }
}
