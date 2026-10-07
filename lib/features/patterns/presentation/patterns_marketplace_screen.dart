import 'package:flutter/material.dart';

import '../../../core/constants/commission.dart';
import '../../../core/roles/user_role.dart';
import '../../../shell/placeholder_page.dart';

/// Marketplace patrons PDF — placeholder.
class PatternsMarketplaceScreen extends StatelessWidget {
  const PatternsMarketplaceScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isDesigner = role == UserRole.designer;
    return PlaceholderPage(
      title: isDesigner ? 'Mes patrons' : 'Patrons',
      subtitle: isDesigner
          ? 'Vente Stripe Connect'
          : 'Marketplace PDF',
      body: isDesigner
          ? 'Espace designer : mise en vente de patrons PDF. '
              'Commission SewsApp : '
              '${DesignerCommission.foundingRatePercent} % founding '
              '(${DesignerCommission.foundingQuota} premières) / '
              '${DesignerCommission.standardRatePercent} % ensuite (sur HT).'
          : 'Parcourir et acheter des patrons PDF. '
              'Checkout Stripe à brancher plus tard.',
      icon: Icons.picture_as_pdf_outlined,
    );
  }
}
