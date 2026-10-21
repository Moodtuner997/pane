# CLAUDE.md — fork Pane (Moodtuner997/pane)

Fichier propre au fork, sur `dev` seulement : ne jamais l'inclure dans une PR vers l'amont. Le
dépôt est public : rien de personnel ni d'infrastructure privée ici.

Pane (`ItsJazii/pane`, MIT) est un portage Windows d'OpenUsage : icône dans la zone de notification,
limites de session 5 h et hebdomadaires des abonnements IA, dates de remise à zéro. Ce fork existe
pour (1) tourner sans mises à jour automatiques ni télémétrie, (2) corriger nous-mêmes et
contribuer en amont (issues, PR).

## Avant toute action
- Lire `HANDOFF.md` s'il existe (non versionné, exclu par `.git/info/exclude`), puis vérifier
  l'état réel : `git fetch --prune; git fetch upstream`, `git log -5 dev`, retard sur l'amont
  (`git rev-list --count dev..upstream/main`), version installée et API locale (plus bas). En cas
  d'écart, la réalité gagne.
- `main` : miroir de `upstream/main`, jamais de commit perso. `dev` : build perso =
  `upstream/main` + patchs fork + ce fichier ; c'est ce qui est installé. Ne jamais pousser `dev`
  ni ce fichier vers l'amont.
- `fix/<n°-issue>` part de `upstream/main` (jamais de `dev`) → PR vers `ItsJazii/pane`. Règles amont
  (`CONTRIBUTING.md`) : issue d'abord, une PR = un changement, pas de nouvelle dépendance sans
  raison, jamais de télémétrie.
- Ne jamais lire ni committer les fichiers d'identifiants des fournisseurs ni leurs copies
  (`~\.claude\.credentials.json`, `.credentials.json.pane-bak`, `~\.codex\auth.json`).
- `git add` fichier par fichier : `npm install` et le build salissent `package-lock.json` (version
  de npm différente de l'amont) et `src-tauri/Cargo.toml` (fins de ligne) ; ne pas les committer.

## Ce que fait l'app
Tauri 2 : cœur Rust (`src-tauri/src/`, un module par fournisseur dans `providers/`), interface
TypeScript/Vite (`src/main.ts`). À intervalle réglable, chaque fournisseur activé lit les
identifiants déjà posés par l'outil officiel et appelle l'API de ce fournisseur (Claude :
`api.anthropic.com/api/oauth/usage`). Appels réseau : `docs/privacy.md` (sans télémétrie ni mise à
jour, il reste les API des fournisseurs et les tables de prix) ; par fournisseur :
`docs/providers.md`. Un nouveau fournisseur exige sa section dans `docs/providers.md`.

## Patchs fork (sur `dev`, à préserver à chaque rebase)
| Fichier | Patch | Effet |
|---|---|---|
| `src-tauri/src/lib.rs` `live_update_check` | `return Ok(None)` en tête | jamais de bannière ni d'installation d'une release amont |
| `src-tauri/src/lib.rs` refresh | `telemetry::record(false, …)` | rien envoyé à PostHog, `%APPDATA%\Pane\telemetry.json` supprimé |
| `src-tauri/tauri.conf.json` | `createUpdaterArtifacts: false` | le build ne réclame pas la clé de signature amont |

Après chaque rebase : `git grep -n 'telemetry::record(' -- src-tauri/src/lib.rs` ne doit montrer que
`false`, `live_update_check` commence par `return Ok(None)`, `createUpdaterArtifacts` vaut `false`.
Conséquence assumée : **pas de mise à jour automatique**. Nouvelle version amont = rebase +
recompilation.

## Commandes (PowerShell)
Suivre l'amont (arbre propre d'abord, `git status` : `git rebase` refuse un arbre sale) :
```powershell
git fetch upstream; git switch main; git merge --ff-only upstream/main; git push origin main
git switch dev; git rebase main; git push --force-with-lease origin dev
```
Recompiler et réinstaller (toolchain Rust et VS Build Tools sur le disque de données, `RUSTUP_HOME`
et `CARGO_HOME` en variables utilisateur ; ouvrir un terminal neuf) :
```powershell
npm install
Stop-Process -Name pane -ErrorAction SilentlyContinue
npm run tauri build          # plusieurs minutes ; target/ pèse plusieurs Go, il reste hors du disque système
& (Get-ChildItem .\src-tauri\target\release\bundle\nsis\Pane_*_x64-setup.exe | Sort-Object LastWriteTime | Select-Object -Last 1).FullName /S
```
La version du setup suit `src-tauri/tauri.conf.json`. Installé dans `%LOCALAPPDATA%\Pane\pane.exe` ;
réglages et caches dans `%APPDATA%\Pane\`.

## Déboguer
- **API locale** (lecture seule) : `Invoke-RestMethod http://127.0.0.1:6736/v1/usage` donne l'état
  de chaque fournisseur (`status: ok|error`, lignes), sans le texte d'erreur. Doc :
  `docs/local-http-api.md`.
- **Voir les erreurs** : le build release n'a pas de console. `npm run tauri dev` (console,
  rechargement à chaud du front) affiche les `eprintln!("[pane] …")` et les erreurs fournisseurs.
  Fermer d'abord la version installée (même port 6736).
- **Absence de télémétrie** : la preuve est le code (patchs ci-dessus) ;
  `Test-Path $env:APPDATA\Pane\telemetry.json` → `False`. `Get-DnsClientCache | Where-Object Entry
  -match 'posthog|trypane'` vide n'est qu'un indice (le cache expire).
- **Identifiants réécrits** : quand un jeton expire, Pane le renouvelle et réécrit le fichier
  d'identifiants de l'outil (copie `.pane-bak` faite avant). Claude Code fait pareil : en cas de
  conflit, relancer `claude` ou `codex login`.
- Un fournisseur sans abonnement se désactive dans les réglages plutôt que de déboguer son erreur.

## Erreurs à ne pas reproduire
- Ne pas installer la toolchain sur le disque système : VS Build Tools a échoué en code 1603, disque
  plein (2026-09-23).
- Ne pas écrire de version, de nom d'installeur ni d'état des fournisseurs dans ce fichier : trois
  faits périmés en moins de 24 h ont dû être corrigés (d2f6bf6, 2026-09-24).
- Ne pas `git add -A` après un build : `package-lock.json` et `src-tauri/Cargo.toml` salis
  partiraient avec (constaté depuis le 2026-09-23).
- Ne pas croire que `main` ou l'app installée suivent l'amont : sans rebase ni recompilation, aucun
  correctif amont n'arrive (retard mesuré en dizaines de versions le 2026-10-21).
- Ne pas relancer un login pour un fournisseur abandonné : le désactiver (Codex et Copilot, octobre
  2026).

## Où est l'état
`HANDOFF.md` local (non versionné) et `git log`.
