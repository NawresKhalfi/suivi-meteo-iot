# suivimétéo — instructions de travail

Application Flutter de suivi de météo. Le backlog produit
(34 user stories, 12 epics) vit dans
`specifications/backlog_user_stories_rationalise.xlsx`. C'est la source de
vérité pour ce qu'il faut construire.

## Méthode de travail (à respecter à chaque nouvelle fonctionnalité)

1. **Implémenter feature par feature**, jamais plusieurs epics en parallèle.
   Une "feature" = un epic du backlog (ou un sous-ensemble cohérent si l'epic
   est gros). Ne pas anticiper les epics suivants au-delà du strict nécessaire
   pour brancher un écran de transition minimal.
2. **Suivi des fonctionnalités** : `docs/FEATURES.md` liste les 34 user
   stories groupées par epic avec un statut (⬜ non démarré / 🟨 en cours /
   ✅ implémenté). Mettre à jour ce fichier à la fin de chaque feature —
   c'est le "check" de ce qui a déjà été livré, à consulter avant de
   commencer une nouvelle feature pour éviter les doublons.
3. **Tests obligatoires pour chaque feature** :
   - Tests unitaires pour la logique (controllers Riverpod, resolvers,
     validators, repositories) sous `test/.../application|domain|data/`.
   - Tests UI (widget tests Flutter) pour les écrans, sous
     `test/.../presentation/`. Ils tournent via la **virtualisation Flutter**
     (`flutter test`, le "flutter tester" headless) — **pas** de device réel
     ni `integration_test`. (Le dossier `ui-test/` à la racine est un sujet
     séparé : smoke test Maestro/Firebase App Distribution sur device réel en
     CI, ne pas le confondre avec les tests Flutter du dossier `test/`.)
   - Lancer `flutter test` avant de considérer une feature terminée.
4. **Fichiers courts** : viser max ~500 lignes par fichier. Découper en
   petits widgets/fonctions plutôt que des fichiers monolithiques.
5. **Organisation en dossiers/sous-dossiers**, miroir entre `lib/` et `test/`
   (voir structure ci-dessous).
6. **UI soignée et intuitive** : Material 3, boutons larges et lisibles
   (contexte de stress post-accident), copy claire, pas d'ambiguïté sur ce
   que l'app fait vs ce que l'utilisateur doit faire lui-même (ex :
   transmission à l'assurance = responsabilité utilisateur, cf. US-002).

## Architecture technique

- **State management** : Riverpod (`flutter_riverpod`, `Notifier`/
  `NotifierProvider`). Toute logique métier vit dans des controllers
  Riverpod testables sans widget (via `ProviderContainer` en test).
- **Navigation** : `go_router`. Router déclaré dans
  `lib/core/router/app_router.dart`.
- **Stockage local** : `shared_preferences` via le wrapper
  `lib/core/storage/local_preferences.dart` (`LocalPreferences`), injecté
  par provider (`localPreferencesProvider`, surchargé dans `main.dart` avec
  l'instance réelle chargée avant `runApp`). Chaque feature ajoute son
  propre "local store" typé dans sa couche `data/` plutôt que de manipuler
  des clés brutes partout. Si une feature a besoin de données relationnelles
  plus riches (constats, véhicules...), réévaluer vers une solution
  structurée (ex. Drift) le moment venu — ne pas le faire prématurément.
- **Firebase** : uniquement avec consentement explicite de l'utilisateur
  . Ne jamais pousser de données par défaut.

- **Thème** : `lib/core/theme/app_theme.dart`.
 je veut un théme moderne et jolie lié à météo
## Structure des dossiers

```
lib/
  main.dart                 # init Firebase + SharedPreferences + runApp
  app.dart                  # MaterialApp.router, theme, locale, l10n
  core/                     # infra transverse, pas de logique métier produit
    router/
    theme/
    storage/
    localization/
  features/
    <feature>/               # un dossier par epic/feature (ex: onboarding)
      domain/                 # modèles, enums, règles pures
      data/                   # repositories / local stores
      application/            # controllers Riverpod (state + use cases)
      presentation/
        screens/
        widgets/
  
  
test/
  core/...                  # miroir de lib/core
  features/<feature>/
    domain/ data/ application/ presentation/   # miroir de lib/features/<feature>
```

## État d'avancement

Voir `docs/FEATURES.md` pour le détail complet epic par epic.
