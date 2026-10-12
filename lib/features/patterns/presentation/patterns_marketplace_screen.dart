import 'package:flutter/material.dart';

import '../../../core/constants/commission.dart';
import '../../../core/roles/user_role.dart';
import '../../auth/data/user_profile.dart';
import '../data/pattern_listing.dart';
import '../data/pattern_purchase.dart';
import '../data/patterns_repository.dart';
import 'pattern_card.dart';
import 'pattern_detail_screen.dart';
import 'pattern_edit_screen.dart';

/// Marketplace patrons PDF — catalogue couturière / mes patrons designer.
class PatternsMarketplaceScreen extends StatefulWidget {
  const PatternsMarketplaceScreen({
    super.key,
    required this.role,
    this.profile,
    this.source,
  });

  final UserRole role;
  final UserProfile? profile;
  final PatternsSource? source;

  @override
  State<PatternsMarketplaceScreen> createState() =>
      _PatternsMarketplaceScreenState();
}

class _PatternsMarketplaceScreenState extends State<PatternsMarketplaceScreen> {
  late final PatternsSource _source = widget.source ?? PatternsRepository();

  bool _loading = true;
  String? _error;
  List<PatternListing> _patterns = const [];
  List<PatternPurchase> _purchases = const [];
  Set<String> _ownedIds = {};
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

  bool get _isDesigner => widget.role == UserRole.designer;

  String get _title => _isDesigner ? 'Mes patrons' : 'Patrons';

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
      final List<PatternListing> patterns;
      if (_isDesigner) {
        final authorId = widget.profile?.id;
        if (authorId == null || authorId.isEmpty) {
          throw const PatternsFailure(
            'Profil introuvable — impossible de charger vos patrons.',
          );
        }
        patterns = await _source.fetchDesignerPatterns(authorId);
      } else {
        patterns = await _source.fetchPublishedCatalog(
          typeFilter: _typeFilter == 'Tous' ? null : _typeFilter,
        );
      }

      List<PatternPurchase> purchases = const [];
      Set<String> owned = {};
      if (!_isDesigner) {
        purchases = await _source.fetchMyPurchases();
        owned = await _source.fetchPurchasedPatternIds();
        for (final p in purchases) {
          owned.add(p.patternId);
        }
      }

      if (!mounted) return;
      setState(() {
        _patterns = patterns;
        _purchases = purchases;
        _ownedIds = owned;
        _loading = false;
      });
    } on PatternsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible de charger les patrons. Vérifiez votre réseau et réessayez.';
        _loading = false;
      });
    }
  }

  void _onFilterSelected(String value) {
    if (value == _typeFilter) return;
    setState(() => _typeFilter = value);
    _load();
  }

  Future<void> _openDetail(PatternListing pattern) async {
    final isOwner =
        _isDesigner && widget.profile?.id == pattern.authorId;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PatternDetailScreen(
          patternId: pattern.id,
          role: widget.role,
          initialPattern: pattern,
          source: _source,
          owned: _ownedIds.contains(pattern.id),
          isOwner: isOwner,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<PatternListing>(
      MaterialPageRoute(
        builder: (_) => PatternEditScreen(source: _source),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patron enregistré.')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _isDesigner
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _isDesigner
                  ? 'Vos fiches `patterns`. Commission SewsApp : '
                      '${DesignerCommission.foundingRatePercent} % founding / '
                      '${DesignerCommission.standardRatePercent} % standard '
                      '(Stripe Connect à brancher).'
                  : 'Catalogue des patrons publiés. '
                      'L’achat Stripe arrive dans une prochaine version.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (!_isDesigner) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _typeOptions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = _typeOptions[index];
                  return FilterChip(
                    label: Text(value),
                    selected: _typeFilter == value,
                    onSelected: _loading
                        ? null
                        : (_) => _onFilterSelected(value),
                  );
                },
              ),
            ),
          ],
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des patrons…'),
          ],
        ),
      );
    }

    if (_error != null) {
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (!_isDesigner && _purchases.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Mes achats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _purchases.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final purchase = _purchases[index];
                    return ActionChip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(purchase.titleLabel),
                      onPressed: () {
                        final match = _patterns
                            .where((p) => p.id == purchase.patternId)
                            .toList();
                        if (match.isNotEmpty) {
                          _openDetail(match.first);
                        } else {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => PatternDetailScreen(
                                patternId: purchase.patternId,
                                role: widget.role,
                                source: _source,
                                owned: true,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          if (_patterns.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isDesigner
                            ? 'Aucun patron pour le moment'
                            : 'Aucun patron publié',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isDesigner
                            ? 'Créez votre première fiche avec le bouton Nouveau.'
                            : 'Revenez plus tard ou changez de filtre.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pattern = _patterns[index];
                    return PatternCard(
                      pattern: pattern,
                      owned: _ownedIds.contains(pattern.id),
                      showStatus: _isDesigner,
                      onTap: () => _openDetail(pattern),
                    );
                  },
                  childCount: _patterns.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
