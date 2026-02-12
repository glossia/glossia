---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---
Una de nuestras prioridades desde el inicio con `l10n` fue lograr que las traducciones se sintieran como una parte natural del flujo de trabajo de desarrollo. No algo que recuerdes hacer antes de un lanzamiento. No un paso que alguien deba activar manualmente. Simplemente algo que ocurre, automáticamente, cada vez que el contenido cambia.

La idea es simple: cada `push` a `main` activa una tarea de CI que verifica si alguna traducción está desactualizada y, en caso afirmativo, genera nuevas y abre un pull request. Todo el proceso toma alrededor de un minuto y funciona con cualquier sistema de CI.

## Cómo funciona

El flujo tiene tres pasos, que se mapean directamente a los comandos de `l10n`.

**1. Comprobar si hay algo desactualizado.** Ejecuta `l10n status`. Esto compara el estado actual de tus archivos fuente y sus traducciones con los archivos de bloqueo que mantiene `l10n`. Si todo está al día, la tarea finaliza antes. Sin consumo de recursos inútil, sin ruido.

**2. Traducir lo que ha cambiado.** Si `l10n status` detecta que algo está desactualizado, ya sea porque un archivo fuente cambió, el contexto se actualizó o falta una traducción por completo, ejecuta `l10n translate`. Aquí es donde el LLM hace su trabajo: lee tu contenido fuente, aplica el contexto que has escrito en tus archivos `L10N.md` y produce traducciones que respetan el tono y la terminología de tu proyecto.

**3. Abrir un pull request.** Si algún archivo ha cambiado, crea una rama, haz `commit` de las traducciones actualizadas y abre un pull request. Si ya existe un PR de traducción, actualízalo en lugar de crear duplicados.

Deliberadamente abrimos un pull request en lugar de enviar las traducciones directamente a `main`. Esto te da la oportunidad de revisar el resultado, iterar sobre el contexto de traducción en tus archivos `L10N.md` y generar confianza en el flujo de trabajo autónomo. Una vez que confíes lo suficiente en los resultados, el objetivo es omitir por completo el paso del PR y hacer `commit` de las traducciones directamente a `main`, haciendo que el proceso sea totalmente invisible.

También querrás omitir los `commits` que provienen de la propia tarea de traducción (para evitar bucles infinitos) y los `commits` de lanzamiento.

## Ejemplo: GitHub Actions

Aquí tienes un ejemplo concreto usando GitHub Actions, pero la misma lógica se aplica a GitLab CI, CircleCI, Buildkite o cualquier otro sistema de CI:

```yaml
name: Translate

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  translate:
    name: Translate
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v5

      - uses: jdx/mise-action@v2

      - name: Check translation status
        id: status
        run: |
          if l10n status; then
            echo "stale=false" >> "$GITHUB_OUTPUT"
          else
            echo "stale=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Run translations
        if: steps.status.outputs.stale == 'true'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: l10n translate

      - name: Create PR with translations
        if: steps.status.outputs.stale == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          if [ -z "$(git status --porcelain)" ]; then
            exit 0
          fi
          BRANCH="l10n/update-translations"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "$BRANCH"
          git add -A
          git commit -m "[l10n] Update translations"
          git push --force origin "$BRANCH"
          gh pr create \
            --title "[l10n] Update translations" \
            --body "Automated translation update." \
            --head "$BRANCH" \
            --base main
```

Deberás añadir tu clave API del LLM como un secreto en tu entorno de CI. Nosotros usamos Claude de Anthropic, por lo que la nuestra es `ANTHROPIC_API_KEY`. Si usas OpenAI, cámbiala por `OPENAI_API_KEY` y actualiza tu configuración de `L10N.md` en consecuencia.

## Por qué esto es importante

Lo importante es que los desarrolladores nunca son interrumpidos. Escriben contenido en el idioma fuente, abren su PR, lo revisan y lo fusionan. Sin pasos adicionales, sin barreras de traducción que bloqueen su trabajo.

Sí, existe una breve ventana de inconsistencia lingüística después de una fusión, donde el contenido fuente ha cambiado pero las traducciones aún no se han actualizado. Para la mayoría de los proyectos, esto está completamente bien. Y es de corta duración: en un minuto desde la fusión, la CI detecta el cambio y abre un PR de traducción con un resultado actualizado.

Al principio, alguien del equipo revisa y fusiona ese PR de traducción. Esta es la fase en la que generas confianza en los resultados e iteras sobre tus archivos de contexto `L10N.md` para acertar con el tono y la terminología. Con el tiempo, a medida que confíes en el resultado, podrás omitir completamente el paso del PR y hacer que las traducciones se envíen directamente a `main`, haciendo que todo el proceso sea invisible.

Dado que `l10n` valida su propia salida (comprobaciones de sintaxis, verificación de tokens a preservar y cualquier comando personalizado que hayas configurado), las traducciones ya han pasado los controles de calidad antes de llegar a ti.

## Qué sigue: convertir las revisiones humanas en memoria lingüística

Hoy, cuando un revisor detecta un problema de traducción y lo corrige manualmente, ese conocimiento reside únicamente en el `git diff`. La próxima vez que `l10n` traduzca una frase similar, no tendrá forma de conocer la corrección.

Queremos cambiar eso. Estamos explorando cómo convertir las revisiones humanas de los PR de traducción en memoria lingüística que `l10n` pueda aplicar a futuras traducciones. La idea es simple: si un revisor cambia "click here" a "tap here" en un contexto móvil, `l10n` debería aprender esa preferencia y aplicarla en adelante.

Esto no se trata de construir una base de datos de memoria de traducción tradicional. Se trata de capturar el bucle de retroalimentación que ya existe en las revisiones de pull request y retroalimentarlo al contexto de traducción. Las correcciones ya están ocurriendo en tu repositorio. Solo necesitamos hacer que perduren.

Todavía estamos definiendo la forma correcta para esto, pero la dirección es clara: cada revisión humana debería mejorar las traducciones futuras, automáticamente.

## Empezar

Si quieres configurar esto para tu proyecto, instala `l10n` e inicializa tu configuración:

```bash
mise use github:tuist/l10n
l10n init
```

Configura tus archivos fuente y lenguajes destino en `L10N.md`, añade una tarea de traducción a tu pipeline de CI y establece tu clave API como un secreto. A partir de ese momento, cada `push` a `main` mantendrá tus traducciones sincronizadas.
