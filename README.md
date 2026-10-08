# SewsApp

Rebuild greenfield de [sewsapp.com](https://www.sewsapp.com) : app couture (feed, marketplace patrons, marchand de tissus) en **Flutter** + **Supabase** + **Stripe Connect**.

Cette version branche la **connexion / inscription**, le **fil d’actualité** et la **publication d’un projet** sur Supabase (clé **anon** uniquement).

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) stable (3.24+ recommandé)
- Un compte SewsApp existant **ou** la possibilité de créer un compte (si les inscriptions sont ouvertes dans Auth)

```bash
flutter doctor
```

## Lancer en local (simple)

1. Récupérer la clé **anon** dans le dashboard Supabase → *Project Settings* → *API*  
   (ne jamais utiliser ni coller la clé `service_role` dans l’app).
2. Dans un terminal, à la racine du projet :

```bash
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://uwszstlhdrkxznygdloe.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

Remplacez `VOTRE_CLE_ANON` par la clé anon (elle ressemble à un long jeton JWT).  
Important : `SUPABASE_URL` doit être la **racine** du projet (`https://….supabase.co`), pas l’URL `/rest/v1`.  
Sur téléphone / simulateur : retirez `-d chrome` ou choisissez `-d ios` / `-d android`.

Sans `--dart-define`, l’app affiche un écran « configuration manquante » (pas de secrets dans le dépôt).

Variables documentées dans [`.env.example`](.env.example) (le fichier `.env` local est ignoré par git).

## Se connecter (pour tester)

1. Lancez l’app avec les `--dart-define` ci-dessus.
2. Sur l’écran **Se connecter**, saisissez l’e-mail et le mot de passe d’un compte existant.
3. Ou appuyez sur **Créer un compte** (si Auth autorise les inscriptions).
4. Après connexion, l’onglet **Feed** charge les posts prod (`posts` + auteur `profiles`).
5. Tirez vers le bas pour actualiser ; filtres type (Robes, Hauts…) en haut.
6. Appuyez sur **Publier** (ou l’icône +) → titre / légende / description → **Publier**.  
   L’upload d’image vers Storage peut être refusé par RLS : dans ce cas, collez une **URL** d’image ou publiez sans photo.
7. Onglet **Profil** → **Se déconnecter**.

| Valeur en base (`account_type`) | Affiché dans l’app |
|---------------------------------|--------------------|
| `Regular User` | Couturière |
| `Designer` | Designer |
| `Seller` | Marchand de tissus |

Si le profil est introuvable, l’app utilise **Couturière** par défaut.

## Structure

```
lib/
  core/           # config (--dart-define), client Supabase, thème, rôles
  features/
    auth/         # login, signup, session, lecture profiles
    feed/         # fil posts + publier un projet + filtres type
    patterns/
    fabric_merchant/
    profile/      # profil + déconnexion + stock
  shell/          # NavigationBar selon le rôle
docs/architecture.md
```

## Hors scope de ce PR

Likes/commentaires, Stripe live, migration / modification du schéma Supabase prod.
