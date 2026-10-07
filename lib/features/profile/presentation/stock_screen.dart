import 'package:flutter/material.dart';

import '../../../shell/placeholder_page.dart';

/// Stock personnel couturière (tissus & patrons) — placeholder.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Mon stock',
      subtitle: 'Tissus & patrons',
      body:
          'Inventaire personnel côté couturière. '
          'Matching stash ↔ patrons et sync Supabase à venir.',
      icon: Icons.inventory_2_outlined,
    );
  }
}
