%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente en su lugar. Glossia revisa los archivos fuente por claridad, precisión y tono usando el contexto que proporcionas, luego produce versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Comenzar",
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
        "El contenido revisado puede sobrescribir el original o escribir a una ruta separada. Siempre controlas el destino de salida.",
      icon: "shield-check"
    },
    %{
      title: "Bucle de retroalimentación",
      description:
        "Los revisores corrigen el resultado, actualizan el contexto y cada ciclo reduce la brecha entre el borrador y el resultado final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona el proceso de revisión

El agente lee tus archivos fuente y el grafo de contexto, integrando las instrucciones locales (archivos `L10N.md` en el directorio raíz o en subdirectorios) con el contexto remoto (tu configuración de voz, terminología y estilo a nivel de cuenta). Con todo ensamblado, reescribe el contenido para mayor claridad, exactitud y tono, y luego genera la versión revisada lista para su revisión.

## Grafo de contexto

El contexto en Glossia es un grafo que abarca tu cuenta y tu repositorio. Los ajustes a nivel de cuenta como la voz y la terminología proporcionan una línea base global, mientras que los archivos `L10N.md` colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este grafo en cada ejecución, para que tus instrucciones permanezcan consistentes entre los archivos sin necesidad de repetírtelo. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya ha sido procesado, de modo que solo se revisa el contenido modificado o nuevo.

## Refinamiento progresivo

Cada ciclo de revisión mejora la salida. Las correcciones retroalimentan los archivos de contexto, de modo que los errores repetidos desaparecen y la salida converge en el estándar de tu equipo con el tiempo.