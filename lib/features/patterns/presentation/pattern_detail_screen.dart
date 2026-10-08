import 'package:flutter/material.dart';

import '../../../core/constants/commission.dart';
import '../../../core/roles/user_role.dart';
import '../data/pattern_listing.dart';
import '../data/patterns_repository.dart';
import 'pattern_edit_screen.dart';

/// Fiche détail patron + stub achat Stripe.
class PatternDetailScreen extends StatefulWidget {
  const PatternDetailScreen({
    super.key,
    required this.patternId,
    required this.role,
    this.initialPattern,
    this.source,
    this.owned = false,
    this.isOwner = false,
  });

  final String patternId;
  final UserRole role;
  final PatternListing? initialPattern;
  final PatternsSource? source;
  final bool owned;
  final bool isOwner;

  @override
  State<PatternDetailScreen> createState() => _PatternDetailScreenState();
}

class _PatternDetailScreenState extends State<PatternDetailScreen> {
  late final PatternsSource _source = widget.source ?? PatternsRepository();

  PatternListing? _pattern;
  bool _loading = true;
  String? _error;
  late final bool _owned = widget.owned;

  @override
  void initState() {
    super.initState();
    _pattern = widget.initialPattern;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _pattern == null;
      _error = null;
    });
    try {
      final pattern = await _source.fetchById(widget.patternId);
      if (!mounted) return;
      setState(() {
        _pattern = pattern;
        _loading = false;
      });
    } on PatternsFailure catch (e) {
      if (!mounted) return;
      if (_pattern != null) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_pattern != null) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _error = 'Impossible de charger ce patron. Réessayez.';
        _loading = false;
      });
    }
  }

  Future<void> _showPurchaseStub() async {
    final pattern = _pattern;
    if (pattern == null) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acheter ce patron'),
        content: SingleChildScrollView(
          child: Text(
            'Le paiement Stripe n’est pas encore branché dans cette version.\n\n'
            'Prochaine étape : checkout Stripe Connect (Edge Function), '
            'commission SewsApp '
            '${DesignerCommission.foundingRatePercent} % founding '
            '(${DesignerCommission.foundingQuota} premières) / '
            '${DesignerCommission.standardRatePercent} % standard, '
            'puis livraison PDF.\n\n'
            'Patron : ${pattern.name}\n'
            'Prix : ${pattern.priceLabel}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit() async {
    final pattern = _pattern;
    if (pattern == null) return;
    final updated = await Navigator.of(context).push<PatternListing>(
      MaterialPageRoute(
        builder: (_) => PatternEditScreen(
          existing: pattern,
          source: _source,
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _pattern = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patron mis à jour.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pattern = _pattern;

    return Scaffold(
      appBar: AppBar(
        title: Text(pattern?.name ?? 'Patron'),
        actions: [
          if (widget.isOwner && pattern != null)
            IconButton(
              tooltip: 'Modifier',
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement du patron…'),
                ],
              ),
            )
          : _error != null
              ? Center(
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
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : pattern == null
                  ? const Center(child: Text('Patron introuvable.'))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: pattern.primaryImageUrl == null
                              ? ColoredBox(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  child: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 64,
                                  ),
                                )
                              : Image.network(
                                  pattern.primaryImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      ColoredBox(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                    ),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pattern.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pattern.authorLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text(pattern.priceLabel)),
                                  if (pattern.type != null)
                                    Chip(label: Text(pattern.type!)),
                                  if (pattern.difficulty != null)
                                    Chip(label: Text(pattern.difficulty!)),
                                  if (_owned)
                                    Chip(
                                      avatar: Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      label: const Text('Possédé'),
                                    ),
                                  if (widget.isOwner)
                                    Chip(
                                      label: Text(pattern.statusLabelFr),
                                    ),
                                ],
                              ),
                              if (pattern.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Description',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pattern.description.trim(),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 28),
                              if (widget.isOwner)
                                Text(
                                  'Commission SewsApp : '
                                  '${DesignerCommission.foundingRatePercent} % '
                                  'founding / '
                                  '${DesignerCommission.standardRatePercent} % '
                                  'standard (à brancher avec Stripe Connect).',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              else if (_owned)
                                FilledButton.tonalIcon(
                                  onPressed: null,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Déjà dans vos achats'),
                                )
                              else if (widget.role != UserRole.designer)
                                FilledButton.icon(
                                  onPressed: _showPurchaseStub,
                                  icon: const Icon(Icons.shopping_bag_outlined),
                                  label: const Text('Acheter'),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: _showPurchaseStub,
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text(
                                    'Achat (bientôt via Stripe)',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
