import 'package:flutter/material.dart';

/// Page placeholder réutilisable (états vides du scaffold).
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 24),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
