#!/usr/bin/env bash
# Verifica que no se haya colado nada del entorno laboral.
# La invariante que sostiene todo el diseño, ejecutable en vez de escrita en un
# README que se lee una vez. Sale 1 si algo falla.
set -uo pipefail

FAIL=0
ok()   { echo "  OK    $1"; }
bad()  { echo "  FALLA $1"; FAIL=1; }

echo "== aislamiento del devbox personal =="

# 1. ssh-agent del host cortado. Si responde, TODAS las claves cargadas en el
#    host (en la notebook laboral, las de Adhoc) son usables desde acá.
if ssh-add -l >/dev/null 2>&1; then
  bad "el ssh-agent del host responde — SSH_AUTH_SOCK no quedó vacío"
  ssh-add -l | sed 's/^/        /'
else
  ok "ssh-agent del host inaccesible"
fi

# 2. Identidad git personal.
EMAIL="$(git config --global user.email || true)"
case "${EMAIL}" in
  ""|*CAMBIAME*)   bad "user.email sin configurar: '${EMAIL}'" ;;
  *adhoc*)         bad "user.email es corporativo: ${EMAIL}" ;;
  *)               ok  "user.email personal: ${EMAIL}" ;;
esac

# 3. Cuenta de GitHub.
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    ok "gh autenticado como: $(gh api user --jq .login 2>/dev/null || echo '?')"
  else
    bad "gh sin autenticar — falta 'gh auth login'"
  fi
fi

# 4. Ningún MCP del entorno laboral. Es el equivalente del agujero del
#    ssh-agent: un tuqui-adhoc registrado acá lee y escribe en el Odoo de Adhoc.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -qi tuqui; then
    bad "hay un MCP corporativo (tuqui) registrado en este container"
  else
    ok "sin MCPs corporativos registrados"
  fi
fi

# 5. Firma de commits.
if [[ "$(git config --global commit.gpgsign || true)" == "true" ]]; then
  ok "firma de commits activa ($(git config --global user.signingkey))"
else
  echo "  INFO  firma de commits desactivada (opcional)"
fi

echo
[[ ${FAIL} -eq 0 ]] && echo "Todo en orden." || echo "Revisar lo marcado como FALLA."
exit ${FAIL}
