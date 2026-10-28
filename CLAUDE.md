# Pane

## Règles inconditionnelles
- Fork public d'`ItsJazii/pane` : `CLAUDE.md`, `docs/fork.md` et les patchs fork restent sur `dev`, jamais dans une PR vers l'amont ; rien de personnel ni d'infrastructure privée dans le dépôt.
- `main` = miroir de `upstream/main`, jamais de commit perso ; `dev` se pousse sur `origin` seul ; correctif amont = `fix/<n°-issue>` depuis `upstream/main`, issue d'abord, une PR = un changement, jamais de télémétrie.
- Patchs fork (mises à jour auto et télémétrie coupées) à préserver à chaque rebase, avec leur contrôle : `docs/fork.md` ; un nouveau fournisseur exige sa section dans `docs/providers.md`.
- Jamais lire ni committer les fichiers d'identifiants des fournisseurs ni leurs copies (`.credentials.json`, `.credentials.json.pane-bak`, `auth.json`).
- `git add` fichier par fichier : `package-lock.json` et `src-tauri/Cargo.toml` sont salis par `npm install` et le build, ne pas les committer.

<!-- gen:debut -->
Dépôt `Moodtuner997/pane` (projet `pane`, pane, statut actif). Déploiement : aucun (pas de déploiement).
Avant toute action : `gh issue list --label etat` (l'issue État, vérité opérationnelle), `git fetch --prune`, `just --list` (points d'entrée uniformes : test, lint, dev, build, deploy-staging).
Tâches = issues GitHub ; état du dépôt = issue épinglée État ; mémoire longue = nœud `02-projets/pane.md` du second cerveau. Rien d'autre ne fait foi.
Enveloppe : PR vers `dev`, fusion si CI verte ; `staging` et `main` n'avancent que par tag (release.yml, release.sh). Secrets jamais lus. Généré par scripts/claude-md-gen.py : ne pas éditer ce bloc.
<!-- gen:fin -->

## Pièges
- Toolchain Rust et VS Build Tools sur le disque de données, jamais sur le disque système : échec en code 1603, disque plein (2026-09-23).
- Pas de version, de nom d'installeur ni d'état des fournisseurs dans ce fichier : trois faits périmés en moins de 24 h (d2f6bf6, 2026-09-24).
- `main` et l'app installée ne suivent pas l'amont tout seuls : sans rebase ni recompilation aucun correctif n'arrive (180 commits de retard mesurés le 2026-10-28, dizaines de versions le 2026-10-21).
- `git rebase` refuse un arbre sale : `package-lock.json` et `Cargo.toml` le salissent (`git status` le montre depuis septembre) ; poser un tag `backup/dev-<date>` local avant de rebaser.
- Squash de la PR #1 sur `origin/dev` (e3c7f51, 2026-10-22) : le `dev` local retardait d'un commit, `git merge --ff-only origin/dev` avant tout rebase.
- Le build release n'a pas de console et le port 6736 est pris par l'app installée : la fermer avant `npm run tauri dev`.
- Pane réécrit le fichier d'identifiants de l'outil officiel quand le jeton expire (copie `.pane-bak`) : en cas de conflit avec Claude Code, relancer `claude` pour qu'il se reconnecte.
- Fournisseur sans abonnement ou inutilisé : le désactiver dans les réglages, ne pas relancer un login (Copilot sans abonnement, Codex `auth.json` périmé, HANDOFF du 2026-09-23).
