# SewsApp

Rebuild greenfield de [sewsapp.com](https://www.sewsapp.com) : app couture (feed, marketplace patrons, marchand de tissus) en **Flutter** + **Supabase** + **Stripe Connect**.

Ce dépôt contient le **scaffold** (structure, shell multi-rôles, stub Supabase). Pas encore d’auth réelle ni de paiements live.

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) stable (3.24+ recommandé)
- Xcode (iOS) et/ou Android Studio (Android)

```bash
flutter doctor
```

## Lancer en local

```bash
flutter pub get

# Sans secrets (UI navigable, mode placeholder)
flutter run

# Avec Supabase (clés locales uniquement — jamais committer)
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Variables documentées dans [`.env.example`](.env.example).  
Réf. prod données utilisateurs (migration plus tard) : `pbeyfeepdrlfjxanvvwa`.

Cibles utiles : `flutter run -d chrome`, `flutter run -d ios`, `flutter run -d android`.

## Rôles (shell démo)

| Rôle | Navigation |
|------|------------|
| Couturière | Feed · Patrons · Tissus · Stock · Profil |
| Designer | Feed · Mes patrons · Profil |
| Marchand de tissus | Catalogue · Feed · Profil |

Commission designers (constantes produit) : **10 %** founding (20 premières) / **20 %** ensuite. Vente tissus : **native Stripe Connect** (pas Shopify).

## Structure

```
lib/
  core/           # config, supabase stub, thème, rôles, commission
  features/
    auth/         # sélection de rôle (placeholder)
    feed/
    patterns/     # marketplace patrons
    fabric_merchant/
    profile/      # profil + stock couturière
  shell/          # NavigationBar role-aware
docs/architecture.md
```

Voir [docs/architecture.md](docs/architecture.md).

## Hors scope de ce PR

Auth complète, feed réel, Stripe live, migration schema Supabase, stores.
