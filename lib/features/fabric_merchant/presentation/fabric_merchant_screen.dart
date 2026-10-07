import 'package:flutter/material.dart';

import '../../../core/roles/user_role.dart';
import '../../../shell/placeholder_page.dart';

/// Module marchand de tissus — vente native Stripe Connect (pas Shopify).
class FabricMerchantScreen extends StatelessWidget {
  const FabricMerchantScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isMerchant = role == UserRole.marchandTissus;
    return PlaceholderPage(
      title: isMerchant ? 'Mon catalogue' : 'Tissus',
      subtitle: isMerchant
          ? 'Vente native Stripe Connect'
          : 'Catalogue marchands',
      body: isMerchant
          ? 'Dashboard marchand : fiches tissu, stock, ventes. '
              'Vente native dans l’app (Stripe Connect) — pas d’affiliation Shopify V1.'
          : 'Découvrir les tissus des marchands. '
              'Checkout Stripe Connect prévu (module nouveau vs V1 Shopify).',
      icon: Icons.texture_outlined,
    );
  }
}
