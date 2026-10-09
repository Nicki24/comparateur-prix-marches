#!/usr/bin/env bash
# Déploie l'API Laravel (dossier backend/) sur Wasmer Edge.
#
# Utilisation (Git Bash, depuis la racine du projet) :
#   ./scripts/deployer-backend.sh
#
# Le paquet est construit depuis le DERNIER COMMIT (git archive) dans un
# dossier temporaire : le fichier .env local (clés, mots de passe) et les
# dépendances de développement ne partent donc jamais en production.
set -euo pipefail

racine="$(git rev-parse --show-toplevel)"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

if [ -n "$(git -C "$racine" status --porcelain backend)" ]; then
  echo "⚠  Modifications non commitées dans backend/ : elles ne seront PAS déployées."
fi

echo "→ Export de backend/ (dernier commit) vers $build"
git -C "$racine" archive HEAD:backend | tar -x -C "$build"

echo "→ Installation des dépendances de production"
(cd "$build" && composer install --no-dev --optimize-autoloader --no-interaction)

echo "→ Déploiement sur Wasmer Edge"
(cd "$build" && wasmer deploy --non-interactive)

# wasmer deploy peut compléter app.yaml (identifiant de l'app) : on le garde.
cp "$build/app.yaml" "$racine/backend/app.yaml"
echo "✓ Déploiement terminé."
