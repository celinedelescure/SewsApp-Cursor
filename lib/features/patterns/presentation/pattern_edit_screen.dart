import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pattern_listing.dart';
import '../data/patterns_repository.dart';

/// Formulaire FR créer / éditer une fiche `patterns` (champs minimaux).
class PatternEditScreen extends StatefulWidget {
  const PatternEditScreen({
    super.key,
    this.existing,
    this.source,
  });

  final PatternListing? existing;
  final PatternsSource? source;

  @override
  State<PatternEditScreen> createState() => _PatternEditScreenState();
}

class _PatternEditScreenState extends State<PatternEditScreen> {
  late final PatternsSource _source = widget.source ?? PatternsRepository();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  static const _typeOptions = <String>[
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

  String? _type;
  bool _isPublished = true;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController = TextEditingController(
      text: existing == null
          ? ''
          : (existing.price.truncateToDouble() == existing.price
              ? existing.price.toStringAsFixed(0)
              : existing.price.toStringAsFixed(2)),
    );
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _imageUrlController =
        TextEditingController(text: existing?.coverImage ?? '');
    _type = existing?.type;
    if (existing != null) {
      _isPublished = existing.isLive || existing.isPublished;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);
    if (price == null) {
      setState(() => _error = 'Indiquez un prix valide (ex. 12.90).');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final input = PatternListingInput(
      name: _nameController.text.trim(),
      price: price,
      description: _descriptionController.text.trim(),
      coverImageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      type: _type,
      isPublished: _isPublished,
    );

    try {
      final PatternListing result;
      final existing = widget.existing;
      if (existing != null) {
        result = await _source.updatePattern(existing.id, input);
      } else {
        result = await _source.createPattern(input);
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on PatternsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible d’enregistrer. Vérifiez votre réseau et réessayez.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le patron' : 'Nouveau patron'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Champs alignés sur la table `patterns` : nom, prix, '
              'description, image (URL), type, publication.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom du patron',
                hintText: 'Ex. Chemise Nicole',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Le nom est obligatoire.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Prix (EUR)',
                hintText: '12.90',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Le prix est obligatoire.';
                }
                final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                if (parsed == null) return 'Prix invalide.';
                if (parsed < 0) return 'Le prix ne peut pas être négatif.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL de l’image de couverture',
                hintText: 'https://…',
                helperText:
                    'Collez une URL publique (upload Storage à brancher plus tard).',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _type != null && _typeOptions.contains(_type) ? _type : null,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in _typeOptions)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publier dans le catalogue'),
              subtitle: Text(
                _isPublished
                    ? 'Visible pour les couturières (is_published)'
                    : 'Brouillon (is_draft)',
              ),
              value: _isPublished,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _isPublished = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Enregistrer' : 'Créer le patron'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
