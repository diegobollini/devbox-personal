#!/usr/bin/env bash
# Setup one-shot del devbox personal. Idempotente: se puede re-correr.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WS=/workspaces/personal

# Repo de dotfiles a clonar adentro del container. Vacío = se saltea el paso.
# Se clona desde acá y NO con la setting `dotfiles.repository` de VS Code: esa
# es una setting de usuario del HOST y se aplicaría también a los containers
# corporativos, inyectando los dotfiles personales ahí.
DOTFILES_REPO=""

echo "==> chown de los volúmenes (nacen root-owned)"
sudo chown -R vscode:vscode \
  /home/vscode/.ssh \
  /home/vscode/.config/gh \
  /home/vscode/.claude \
  /home/vscode/.cache
chmod 700 /home/vscode/.ssh

echo "==> identidad git"
bash "${HERE}/assert-identity.sh"

echo "==> clave SSH del container"
KEY=/home/vscode/.ssh/id_ed25519
if [[ ! -f "${KEY}" ]]; then
  # Una clave por máquina: si después usás este mismo repo en la notebook
  # personal, esa genera la suya y cargás las dos en GitHub. Revocar una no
  # te deja afuera desde la otra.
  ssh-keygen -t ed25519 -N "" -C "devbox-personal@$(hostname)" -f "${KEY}"
  echo
  echo "    CLAVE NUEVA — cargala DOS VECES en https://github.com/settings/keys :"
  echo "    una como Authentication Key y otra como Signing Key."
  echo
  cat "${KEY}.pub"
  echo
fi
ssh-keyscan -t ed25519 github.com >> /home/vscode/.ssh/known_hosts 2>/dev/null
sort -u -o /home/vscode/.ssh/known_hosts /home/vscode/.ssh/known_hosts

echo "==> historial de shell persistente"
# Sin esto el historial muere en cada rebuild. Reusa el volumen .cache en vez de
# sumar un mount nuevo.
grep -q 'HISTFILE=/home/vscode/.cache' ~/.bashrc || \
  echo 'export HISTFILE=/home/vscode/.cache/.bash_history' >> ~/.bashrc

echo "==> contexto de IA en la raíz del workspace"
# El workspace abre en el PADRE de todos los proyectos, así que un AGENTS.md
# acá lo hereda cualquier proyecto que abras. Symlink relativo para que tampoco
# quede roto visto desde el host.
ln -sfn devbox-personal/AGENTS.md "${WS}/AGENTS.md"
ln -sfn devbox-personal/CLAUDE.md "${WS}/CLAUDE.md"

if [[ -n "${DOTFILES_REPO}" ]]; then
  echo "==> dotfiles"
  if [[ ! -d ~/.dotfiles ]]; then
    git clone "${DOTFILES_REPO}" ~/.dotfiles && \
      { [[ -x ~/.dotfiles/install.sh ]] && bash ~/.dotfiles/install.sh || true; }
  fi
fi

echo "==> Claude Code"
npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 || \
  echo "    (falló el install de claude-code; correlo a mano)"

cat <<'EOF'

==> Pendientes manuales (una vez por máquina):

    1. Cargar la clave pública en https://github.com/settings/keys, DOS veces:
       como Authentication Key y como Signing Key.
       (si no la imprimió arriba, ya existía: cat ~/.ssh/id_ed25519.pub)
    2. gh auth login          -> con tu cuenta PERSONAL
    3. claude /login          -> con tu cuenta personal de Claude

    Quedan en volúmenes, así que sobreviven rebuilds del container.

EOF

echo "==> chequeo de aislamiento"
bash "${HERE}/check-isolation.sh" || true
