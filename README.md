# devbox-personal

Devcontainer para trabajar en proyectos personales desde cualquiera de mis dos
notebooks —incluida la laboral— sin mezclar identidades ni credenciales.

## Qué aísla, y qué no

Aísla **identidad y tooling**:

| Superficie | Cómo |
|---|---|
| Claves SSH | Volumen `personal-ssh`, clave propia del container. El ssh-agent forwarding del host queda cortado (`SSH_AUTH_SOCK: ""`) — si no, las claves Adhoc del host serían usables acá. |
| Auth de GitHub (`gh`) | Volumen `personal-gh`. Nada de bind a `~/.config/gh` del host. |
| Auth de Claude Code | Volumen `personal-claude`. |
| Identidad de git | `identity.env` + `assert-identity.sh`, que corre en cada arranque. Necesario porque Dev Containers **copia el `~/.gitconfig` del host** e inyecta su credential helper. |
| Código | Un solo bind: `~/personal` del host. |
| Contexto de IA | `AGENTS.md` symlinkeado a la raíz del workspace, heredado por todos los proyectos. Sin MCPs corporativos. |

**No** aísla frente al empleador: en la notebook laboral los archivos siguen
viviendo en su disco. Eso es una decisión, no un descuido.

## Setup (una vez por máquina)

```bash
mkdir -p ~/personal
git clone git@github.com:diegobollini/devbox-personal.git ~/personal/devbox-personal
```

El clone tiene que quedar exactamente en `~/personal/devbox-personal`: el
`workspaceMount` monta el padre `~/personal` y los hooks resuelven por ese nombre.

1. Editar `.devcontainer/identity.env` con el email personal. Si queda el
   placeholder, el container **falla al arrancar** a propósito — es preferible a
   commitear en silencio con la identidad de Adhoc.
2. Abrir `~/personal/devbox-personal` en VS Code → *Reopen in Container*.
   Desde una ventana del **host**, no desde adentro de otro devcontainer.
3. Seguir los tres pendientes que imprime el post-create: cargar la clave
   pública en GitHub, `gh auth login`, `claude /login`.

La clave se carga **dos veces** en <https://github.com/settings/keys>: una como
*Authentication Key* y otra como *Signing Key*. Son entradas distintas; sin la
segunda los commits se firman igual pero GitHub los muestra "Unverified".

El workspace se abre en `/workspaces/personal`, así que todos los proyectos
personales aparecen como hermanos de este repo.

## Verificar que no se coló nada del host

```bash
bash devbox-personal/.devcontainer/check-isolation.sh
```

Chequea el ssh-agent del host, la identidad de git, la cuenta de `gh`, que no
haya MCPs corporativos registrados y la firma de commits. Sale 1 si algo falla.

## Sincronizar las dos notebooks

- **Definición del container**: este repo. `git pull` y rebuild.
- **Código**: repos git, como siempre.
- **Auth**: se hace una vez por máquina; vive en los volúmenes y sobrevive rebuilds.
- **Clave SSH**: una por máquina, dos entradas en GitHub. Revocar una no deja
  afuera a la otra.
- **Estado sin commitear**: no se sincroniza. Si hace falta, faltó un commit.

## Dotfiles

`post-create.sh` tiene una variable `DOTFILES_REPO`, vacía por default. Poniéndole
una URL, clona el repo en `~/.dotfiles` y corre su `install.sh` si existe.

Se hace desde el script y **no** con la setting `dotfiles.repository` de VS Code
a propósito: esa es una setting de usuario del host y se aplicaría también a los
containers corporativos, inyectando los dotfiles personales ahí.

## Extender

Herramientas al `post-create.sh`. Runtimes y Docker-in-Docker como *features*
en `devcontainer.json`:

```jsonc
"features": {
  "ghcr.io/devcontainers/features/docker-in-docker:2": { "moby": false }
}
```

`moby: false` porque los paquetes de moby no existen para Debian Trixie.

Si el post-create se vuelve lento, ahí conviene hornear una imagen a ghcr con
tag inmutable y pinearla acá. Antes de eso, no.
