# Points d'entrée du dépôt (`just --list` avant d'agir). Gabarit commun : justfile.node.
set windows-shell := ["bash", "-c"]
set shell := ["bash", "-c"]

# Test unitaire de l'affichage Sub2API (seul test JS du dépôt ; les tests Rust demandent cargo, non lancés ici)
test:
    node --test scripts/sub2api-display.test.mjs

# Vérification des types TypeScript (tsc strict, sans émission)
lint:
    npx tsc --noEmit

# Interface Vite en navigateur (sans le cœur Rust) ; l'app complète : npm run tauri dev
dev:
    npm run dev

# Partie web seule (tsc puis vite build) ; l'installeur Windows : npm run tauri build, plusieurs minutes, toolchain Rust requise
build:
    npm run build

# Pousse dev sur le fork ; pas de staging ni de release sur ce fork
deploy-staging:
    git fetch --prune && git push origin dev
