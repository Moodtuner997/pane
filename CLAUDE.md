# CLAUDE.md — fork Pane (Moodtuner997/pane)

Fichier propre au fork, sur `dev` seulement : ne jamais l'inclure dans une PR vers l'amont.

## Pourquoi ce dépôt existe

OpenUsage (robinebers/openusage) affiche l'usage des abonnements IA (Claude, Codex, Cursor…)
mais n'existe que sur macOS. Pane (`ItsJazii/pane`, MIT) en est le portage Windows le plus
actif : icône dans la zone de notification, fenêtre avec limites de session 5 h, hebdo, dates
de remise à zéro. Forké le 2026-09-23 pour :

1. tourner sur le laptop de Théo **sans mises à jour auto ni télémétrie** ;
2. corriger / améliorer nous-mêmes et **contribuer en amont** (issues, PR).

## Ce que fait l'app

Tauri 2 : cœur Rust (`src-tauri/src/`, un module par fournisseur dans `providers/`), interface
TypeScript/Vite (`src/main.ts`). Toutes les 1 à 5 min, chaque fournisseur activé lit les
identifiants déjà posés par l'outil officiel et appelle l'API de ce fournisseur :

- Claude : `~\.claude\.credentials.json` → `api.anthropic.com/api/oauth/usage` ;
- Codex : `~\.codex\auth.json` → API ChatGPT.

Liste exhaustive des appels réseau : `docs/privacy.md` ; par fournisseur : `docs/providers.md`.

## Branches (exception à la règle dev/staging/main du parc)

- `main` : miroir de `upstream/main` (ItsJazii), jamais de commit perso.
- `dev` : build perso = `upstream/main` + patchs fork + ce fichier. C'est ce qui est installé.
- `fix/<n°-issue>` depuis `upstream/main` → PR vers `ItsJazii/pane`. Règles amont
  (`CONTRIBUTING.md`) : issue d'abord, une PR = un changement, pas de nouvelle dépendance
  sans raison, jamais de télémétrie.

Remotes : `origin` = Moodtuner997/pane, `upstream` = ItsJazii/pane.

Suivre l'amont :

```powershell
git fetch upstream; git switch main; git merge --ff-only upstream/main; git push origin main
git switch dev; git rebase main; git push --force-with-lease origin dev
```

## Patchs fork (sur `dev`, à préserver à chaque rebase)

| Fichier | Patch | Effet |
|---|---|---|
| `src-tauri/src/lib.rs` `live_update_check` | `return Ok(None)` en tête | jamais de bannière ni d'install d'une release amont |
| `src-tauri/src/lib.rs` refresh | `telemetry::record(false, …)` | rien envoyé à PostHog, `%APPDATA%\Pane\telemetry.json` supprimé |
| `src-tauri/tauri.conf.json` | `createUpdaterArtifacts: false` | le build ne réclame pas la clé de signature amont |

Conséquence : **pas de mise à jour automatique**. Nouvelle version amont = rebase + recompile.

## Recompiler et réinstaller

Prérequis déjà installés (2026-09-23), tous sur D: car C: est petit :
VS Build Tools 2022 et Rust dans le dossier `dev` à la racine du disque D (`BuildTools`, `rust`)
(`RUSTUP_HOME`, `CARGO_HOME` en variables utilisateur ; ouvrir un terminal neuf).

```powershell
# depuis la racine du dépôt
npm install
Stop-Process -Name pane -ErrorAction SilentlyContinue
npm run tauri build          # ~6 min 30 au premier build (mesuré le 2026-09-23)
& (Get-ChildItem .\src-tauri\target\release\bundle\nsis\Pane_*_x64-setup.exe | Sort-Object LastWriteTime | Select-Object -Last 1).FullName /S
```

Le numéro de version du setup suit `src-tauri/tauri.conf.json`. Installé dans
`%LOCALAPPDATA%\Pane\pane.exe` ; réglages et caches dans `%APPDATA%\Pane\`.

## Attention

- **Identifiants réécrits** : quand un jeton expire, Pane le renouvelle et réécrit
  `~\.claude\.credentials.json` / `~\.codex\auth.json` (sauvegarde faite avant). Claude Code
  fait pareil : en cas de conflit, relancer `claude` / `codex login`.
- **`package-lock.json` modifié par `npm install`** (version de npm différente de l'amont) :
  ne pas le committer.
- **Disque C:** : petit, déjà arrivé à saturation. Vérifier `(Get-PSDrive C).Free`
  avant toute grosse installation ; `target/` (plusieurs Go) reste sur D:.
- Ne jamais pousser `dev` ni ce fichier vers l'amont.

## Déboguer

- **API locale** (lecture seule) : `Invoke-RestMethod http://127.0.0.1:6736/v1/usage` donne
  l'état de chaque fournisseur (`status: ok|error`, lignes). Doc : `docs/local-http-api.md`.
  Le texte d'erreur n'y figure pas.
- **Voir les erreurs** : le build release n'a pas de console (`windows_subsystem`). Lancer
  `npm run tauri dev` (console, rechargement à chaud du front) : les `eprintln!("[pane] …")`
  et les erreurs fournisseurs s'affichent. Fermer d'abord la version installée (même port 6736).
- **Vérifier l'absence de télémétrie** : `Get-DnsClientCache | Where-Object Entry -match
  'posthog|trypane'` doit être vide ; `Test-Path $env:APPDATA\Pane\telemetry.json` → `False`.
- Copilot : pas d'abonnement, le masquer dans les réglages plutôt que déboguer son erreur. Un
  fournisseur en `error` avec un fichier d'identifiants ancien se règle d'abord par un nouveau login.
