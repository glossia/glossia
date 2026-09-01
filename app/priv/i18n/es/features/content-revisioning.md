%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente en su lugar. Glossia revisa los archivos fuente por claridad, precisión y tono usando el contexto que proporcionas, luego produce versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empieza ahora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan tu redacción por legibilidad, jerga y coherencia con tu voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribirse en una ruta separada. Siempre controlas el destino de salida.",
      icon: "shield-check"
    },
    %{
      title: "Bucle de retroalimentación",
      description:
        "Los revisores corrigen el resultado, actualizan el contexto y cada ciclo acorta la brecha entre el borrador y el final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona la revisión

El agente lee tus archivos fuente y el gráfico de contexto, fusionando las instrucciones locales (archivos `GLOSSIA.md` en la raíz o en subdirectorios) con el contexto remoto (tus configuraciones a nivel de cuenta de voz, terminología y estilo). Con la imagen completa ensamblada, reescribe el contenido para la claridad, precisión y tono, luego exporta la versión revisada lista para su revisión.

## Gráfico de contexto

El contexto en Glossia es un gráfico que abarca tu cuenta y tu repositorio. Las configuraciones a nivel de cuenta como voz y terminología proporcionan una referencia global, mientras que los archivos `GLOSSIA.md` colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este gráfico en cada ejecución, de modo que no tengas que repetirte en los archivos para mantener tus instrucciones consistentes. Las revisiones son incrementales gracias a los archivos de bloqueo que registran lo que ya se ha procesado, de modo que solo el contenido modificado o nuevo vuelve a ser revisado.

## Refinamiento progresivo

Cada ciclo de revisión mejora el resultado. Las correcciones se retroalimentan en los archivos de contexto, de modo que los errores repetidos desaparecen y el resultado converge con el estándar de tu equipo con el tiempo.