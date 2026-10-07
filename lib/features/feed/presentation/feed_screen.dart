import 'package:flutter/material.dart';

import '../../../core/roles/user_role.dart';
import '../../../shell/placeholder_page.dart';

/// Feed projets — placeholder (parité V1 à venir).
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Feed',
      subtitle: 'Créations et inspiration',
      body:
          'Espace feed pour le rôle « ${role.labelFr} ». '
          'Pagination, filtres et publication arriveront dans les prochaines phases.',
      icon: Icons.dynamic_feed_outlined,
    );
  }
}
