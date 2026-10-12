/// Rôles produit SewsApp (rebuild).
enum UserRole {
  /// Couturière — feed, stock, achats.
  couturiere,

  /// Designer — vente de patrons PDF (Stripe Connect).
  designer,

  /// Marchand de tissus — catalogue & ventes natives Stripe Connect.
  marchandTissus,
}

extension UserRoleX on UserRole {
  String get labelFr => switch (this) {
        UserRole.couturiere => 'Couturière',
        UserRole.designer => 'Designer',
        UserRole.marchandTissus => 'Marchand de tissus',
      };

  String get descriptionFr => switch (this) {
        UserRole.couturiere =>
          'Feed projets, stock tissus & patrons, achats marketplace.',
        UserRole.designer =>
          'Mise en vente de patrons PDF via Stripe Connect.',
        UserRole.marchandTissus =>
          'Catalogue tissus, stock et ventes natives (pas Shopify).',
      };

  /// Mappe `profiles.account_type` (prod) vers le rôle Flutter.
  ///
  /// Valeurs live : `Regular User`, `Designer`, `Seller`.
  static UserRole fromAccountType(String? accountType) {
    final normalized = (accountType ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'designer':
        return UserRole.designer;
      case 'seller':
      case 'marchand':
      case 'marchand de tissus':
      case 'marchandtissus':
        return UserRole.marchandTissus;
      case 'regular user':
      case 'couturiere':
      case 'couturière':
      case 'user':
      default:
        return UserRole.couturiere;
    }
  }
}
