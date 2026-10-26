%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente directamente. Glossia revisa los archivos fuente por claridad, precisión y tono utilizando el contexto que proporciones, generando versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan tu redacción por legibilidad, jerga y consistencia con tu voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribir a una ruta separada. Siempre controlas el destino de salida.",
      icon: "shield-check"
    },
    %{
      title: "Bucle de retroalimentación",
      description:
        "Los revisores corrigen la salida, actualizan el contexto y cada ciclo reduce la brecha entre el borrador y la versión final.",
      icon: "refresh-cw"
    }
  ]
}
---

## Cómo funciona la revisión

El agente lee tus archivos de origen y el grafo de contexto, fusionando instrucciones locales (`L10N.md` archivos en la raíz o en subdirectorios) con el contexto remoto (tu voz, glosario y configuraciones de estilo de cuenta). Con toda la información reunida, reescribe el contenido para claridad, precisión y tono, y luego exporta la versión revisada lista para su revisión.

## Grafo de contexto

El contexto en Glossia es un grafo que abarca tu cuenta y tu repositorio. Las configuraciones de nivel de cuenta como la voz y el glosario proporcionan una línea base global, mientras que `L10N.md` archivos colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este grafo en cada ejecución, para que tus instrucciones mantengan la consistencia a través de los archivos sin necesidad de repetírtelo. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya ha sido procesado, de modo que solo el contenido modificado o nuevo vuelve a ser revisado.

## Refinamiento progresivo

Cada ciclo de revisión mejora la salida. Las correcciones se reintegran en los archivos de contexto, para que los errores repetidos desaparezcan y la salida se alinee con el estándar de tu equipo con el tiempo.
