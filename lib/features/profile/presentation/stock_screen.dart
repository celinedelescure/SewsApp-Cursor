import 'package:flutter/material.dart';

import '../../../core/roles/user_role.dart';
import '../../patterns/data/pattern_purchase.dart';
import '../../patterns/data/patterns_repository.dart';
import '../../patterns/presentation/pattern_detail_screen.dart';
import '../data/fabric_item.dart';
import '../data/fabrics_repository.dart';
import 'fabric_edit_screen.dart';

/// Stock personnel couturière — tissus (`fabrics`) + patrons achetés.
class StockScreen extends StatefulWidget {
  const StockScreen({
    super.key,
    this.role = UserRole.couturiere,
    this.source,
    this.fabricsSource,
  });

  final UserRole role;
  final PatternsSource? source;
  final FabricsSource? fabricsSource;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late final PatternsSource _source = widget.source ?? PatternsRepository();
  late final FabricsSource _fabricsSource =
      widget.fabricsSource ?? FabricsRepository();

  bool _loading = true;
  String? _error;
  List<PatternPurchase> _purchases = const [];
  List<FabricItem> _fabrics = const [];

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
      final purchasesFuture = _source.fetchMyPurchases();
      final fabricsFuture = _fabricsSource.fetchMyFabrics();
      final purchases = await purchasesFuture;
      final fabrics = await fabricsFuture;
      if (!mounted) return;
      setState(() {
        _purchases = purchases;
        _fabrics = fabrics;
        _loading = false;
      });
    } on PatternsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on FabricsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible de charger votre stock. Vérifiez votre réseau et réessayez.';
        _loading = false;
      });
    }
  }

  Future<void> _openPurchase(PatternPurchase purchase) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PatternDetailScreen(
          patternId: purchase.patternId,
          role: widget.role,
          source: _source,
          owned: true,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openAddFabric() async {
    final created = await Navigator.of(context).push<FabricItem>(
      MaterialPageRoute(
        builder: (_) => FabricEditScreen(source: _fabricsSource),
      ),
    );
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.titleLabel} ajouté au stock.')),
      );
      await _load();
    }
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon stock'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFabric,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un tissu'),
      ),
      body: _buildBody(Theme.of(context)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _purchases.isEmpty && _fabrics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _purchases.isEmpty && _fabrics.isEmpty) {
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

    final empty = _purchases.isEmpty && _fabrics.isEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (empty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Votre stock est vide',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ajoutez un tissu, ou achetez un patron '
                        'dans l’onglet Patrons.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _openAddFabric,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un tissu'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Mes tissus (${_fabrics.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_fabrics.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Aucun tissu pour l’instant. Utilisez « Ajouter un tissu ».',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: _fabrics.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final fabric = _fabrics[index];
                    return _FabricStockTile(fabric: fabric);
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Patrons achetés (${_purchases.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_purchases.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  child: Text(
                    'Aucun patron acheté. Rendez-vous dans Patrons → Acheter.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList.separated(
                  itemCount: _purchases.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final purchase = _purchases[index];
                    return _PurchaseStockTile(
                      purchase: purchase,
                      dateLabel: _formatDate(purchase.purchasedAt),
                      onTap: () => _openPurchase(purchase),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FabricStockTile extends StatelessWidget {
  const _FabricStockTile({required this.fabric});

  final FabricItem fabric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = fabric.imageUrl?.trim();
    final subtitle = fabric.subtitleLabel;
    final notes = fabric.notes?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: cover == null || cover.isEmpty
                    ? ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.texture_outlined,
                          color: theme.colorScheme.outline,
                        ),
                      )
                    : Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric.titleLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseStockTile extends StatelessWidget {
  const _PurchaseStockTile({
    required this.purchase,
    required this.onTap,
    this.dateLabel,
  });

  final PatternPurchase purchase;
  final VoidCallback onTap;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = purchase.coverImage?.trim();
    final brand = purchase.brand?.trim();
    final price = purchase.priceLabel;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: cover == null || cover.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.picture_as_pdf_outlined,
                            color: theme.colorScheme.outline,
                          ),
                        )
                      : Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.titleLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (brand != null && brand.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          avatar: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          label: const Text('Possédé'),
                        ),
                        if (price != null)
                          Text(
                            price,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (dateLabel != null)
                          Text(
                            dateLabel!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
