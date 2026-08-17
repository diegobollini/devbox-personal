# AGENTS.md — workspace personal

Symlinkeado a la raíz del workspace (`/workspaces/personal`), así que lo hereda
cualquier proyecto personal que se abra acá. Lo específico de cada proyecto va
en el `AGENTS.md` del proyecto, no en este archivo.

## Contexto

Este es el **entorno personal** de Diego Bollini, deliberadamente separado del
entorno de trabajo de Adhoc. Corre en un devcontainer con credenciales propias
en volúmenes Docker (clave SSH, `gh`, Claude Code), sin acceso a las
credenciales del host.

## Reglas

- **Identidad personal, siempre.** Los commits van con la cuenta personal de
  GitHub. Si algo intenta commitear, autenticar o publicar con una identidad
  `@adhoc.inc`, es un error de configuración: frenar y avisar.
- **Sin recursos corporativos.** Nada de MCPs, credenciales, VPNs ni bases de
  Adhoc desde acá. Si una tarea los necesita, es una tarea de trabajo y va en
  el otro entorno.
- **Sin secretos en el repo.** `devbox-personal` es público. La autenticación
  vive en los volúmenes del container y nunca se commitea.

## Tono

Español rioplatense, directo y conciso. Registro profesional: el dialecto
(voseo, "acá", "sacá") sí, el registro informal no. Nada de "che", "quilombo",
"laburo" ni lunfardo en general — ante la duda, el sinónimo neutro.

Ser honesto sobre lo que no se pudo verificar. No inventar IDs, rutas, montos
ni URLs.

## Verificación

Ante cualquier duda sobre si el aislamiento sigue en pie:

```bash
bash devbox-personal/.devcontainer/check-isolation.sh
```
