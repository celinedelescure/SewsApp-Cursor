import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fabric_item.dart';
import '../data/fabrics_repository.dart';

/// Formulaire FR — ajouter un tissu au stock (`fabrics`).
class FabricEditScreen extends StatefulWidget {
  const FabricEditScreen({super.key, this.source});

  final FabricsSource? source;

  @override
  State<FabricEditScreen> createState() => _FabricEditScreenState();
}

class _FabricEditScreenState extends State<FabricEditScreen> {
  late final FabricsSource _source = widget.source ?? FabricsRepository();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _colorController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _notesController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _colorController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  double? _parseOptionalNumber(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final length = _parseOptionalNumber(_lengthController.text);
    if (_lengthController.text.trim().isNotEmpty && length == null) {
      setState(() => _error = 'Longueur invalide (ex. 1.5).');
      return;
    }
    final width = _parseOptionalNumber(_widthController.text);
    if (_widthController.text.trim().isNotEmpty && width == null) {
      setState(() => _error = 'Largeur invalide (ex. 1.4).');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final created = await _source.addFabric(
        FabricItemInput(
          name: _nameController.text.trim(),
          type: _typeController.text.trim(),
          color: _colorController.text.trim(),
          length: length,
          width: width,
          notes: _notesController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on FabricsFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible d’enregistrer le tissu. Réessayez.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un tissu'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Ce tissu sera ajouté à votre stock personnel.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'Ex. Lin lavé ivoire',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Indiquez un nom.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'Ex. Lin, coton, jersey…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _colorController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Couleur',
                hintText: 'Ex. ivoire',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Longueur (m)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Largeur (m)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Magasin, usage prévu…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL de la photo (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
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
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
