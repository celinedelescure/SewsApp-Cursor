import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/feed_repository.dart';
import '../data/publish_repository.dart';

/// Formulaire FR pour créer un post (`posts`).
class PublishProjectScreen extends StatefulWidget {
  const PublishProjectScreen({
    super.key,
    this.source,
  });

  final PublishSource? source;

  @override
  State<PublishProjectScreen> createState() => _PublishProjectScreenState();
}

class _PublishProjectScreenState extends State<PublishProjectScreen> {
  late final PublishSource _source =
      widget.source ?? PublishRepository();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

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
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _error;
  String? _uploadNotice;

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _uploadNotice = null;
      _error = null;
    });

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final name = picked.name.isNotEmpty ? picked.name : 'photo.jpg';
      final mime = _guessMime(name, picked.mimeType);
      final url = await _source.uploadPostImage(
        bytes: Uint8List.fromList(bytes),
        fileName: name,
        contentType: mime,
      );
      if (!mounted) return;
      if (url == null) {
        setState(() {
          _uploadNotice =
              'L’envoi d’image vers le stockage n’est pas autorisé '
              'pour ce compte. Collez une URL d’image ci-dessous, '
              'ou publiez sans photo.';
        });
      } else {
        _imageUrlController.text = url;
        setState(() {
          _uploadNotice = 'Image envoyée. Vous pouvez publier.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploadNotice =
            'Impossible d’envoyer l’image. Utilisez une URL, '
            'ou publiez sans photo.';
      });
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  String _guessMime(String name, String? provided) {
    if (provided != null && provided.startsWith('image/')) return provided;
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final caption = _captionController.text.trim();
    if (title.isEmpty && caption.isEmpty) {
      setState(() {
        _error = 'Indiquez au moins un titre ou une légende.';
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final post = await _source.createPost(
        PublishProjectInput(
          title: title,
          caption: caption,
          description: _descriptionController.text,
          type: _type,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(post);
    } on FeedFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Impossible de publier. Vérifiez votre réseau et réessayez.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _submitting || _uploadingImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier un projet'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Text(
                  'Partagez une création cousue sur le fil.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          hintText: 'Ex. Robe Venice — première version',
                          helperText: 'Enregistré comme nom de projet (pattern_name).',
                        ),
                        validator: (value) {
                          final t = value?.trim() ?? '';
                          final c = _captionController.text.trim();
                          if (t.isEmpty && c.isEmpty) {
                            return 'Titre ou légende requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _captionController,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Légende',
                          hintText: 'Courte phrase visible sur le fil',
                          helperText: 'Colonne caption.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Modifications, tips, tissu…',
                          helperText:
                              'Enregistré dans modifications (pas de colonne description).',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownMenu<String>(
                        initialSelection: _type,
                        enabled: !busy,
                        label: const Text('Type de pièce'),
                        hintText: 'Choisir un type',
                        dropdownMenuEntries: [
                          for (final t in _typeOptions)
                            DropdownMenuEntry(
                              value: t,
                              label: _labelFr(t),
                            ),
                        ],
                        onSelected: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Colonne type (filtres du feed).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Image (optionnel)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _pickAndUploadImage,
                        icon: _uploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _uploadingImage
                              ? 'Envoi en cours…'
                              : 'Choisir une image',
                        ),
                      ),
                      if (_uploadNotice != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _uploadNotice!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlController,
                        enabled: !busy,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL de l’image',
                          hintText: 'https://…',
                          helperText:
                              'Si l’upload est bloqué, collez une URL publique.',
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return null;
                          final uri = Uri.tryParse(v);
                          if (uri == null ||
                              !(uri.isScheme('http') || uri.isScheme('https'))) {
                            return 'URL http(s) invalide';
                          }
                          return null;
                        },
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
                        onPressed: busy ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publier'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFr(String type) {
    switch (type) {
      case 'Dress':
        return 'Robe';
      case 'Top':
        return 'Haut';
      case 'Shirt':
        return 'Chemise';
      case 'Skirt':
        return 'Jupe';
      case 'Trousers':
        return 'Pantalon';
      case 'Shorts':
        return 'Short';
      case 'Coat':
        return 'Manteau';
      case 'Knitwear':
        return 'Maille';
      case 'Intimwear':
        return 'Lingerie';
      default:
        return type;
    }
  }
}
