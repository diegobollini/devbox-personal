#!/usr/bin/env bash
# Afirma la identidad git personal. Corre en cada arranque (postStartCommand),
# no solo al crear: VS Code puede reinyectar la config del host.
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=identity.env
source ./identity.env

if [[ "${GIT_USER_EMAIL}" == "CAMBIAME@example.com" ]]; then
  echo "ERROR: editá .devcontainer/identity.env con tu email personal." >&2
  echo "Sin eso este container commitea con la identidad del host (Adhoc)." >&2
  exit 1
fi

git config --global user.name  "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"

# El credential helper que inyecta Dev Containers hace proxy contra la auth de
# GitHub del HOST. Se saca: acá se usa gh (volumen personal-gh) o SSH.
git config --global --unset-all credential.helper 2>/dev/null || true

# Firma de commits con la misma clave SSH. En GitHub hay que cargar la pública
# UNA SEGUNDA VEZ eligiendo tipo "Signing Key" — es una entrada distinta de la
# de autenticación. Sin eso los commits se firman igual pero salen "Unverified".
SIGNKEY=/home/vscode/.ssh/id_ed25519.pub
if [[ -f "${SIGNKEY}" ]]; then
  git config --global gpg.format ssh
  git config --global user.signingkey "${SIGNKEY}"
  git config --global commit.gpgsign true
fi

echo "git: $(git config --global user.name) <$(git config --global user.email)>"
