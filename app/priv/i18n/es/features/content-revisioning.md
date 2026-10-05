%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente directamente. Glossia revisa los archivos fuente por claridad, precisión y tono usando el contexto que proporcionas, luego genera versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan tu redacción por legibilidad, jerga y consistencia con la voz de tu marca.",
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
        "Los revisores corrigen el resultado, actualizan el contexto y cada ciclo reduce la brecha entre el borrador y el final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona la revisión

El agente lee tus archivos de origen y el grafo de contexto, fusionando las instrucciones locales (`L10N.md` en la raíz o en subdirectorios) con el contexto remoto (tu voz, glosario y configuraciones de estilo a nivel de cuenta). Una vez ensamblada la imagen completa, reescribe el contenido para claridad, exactitud y tono, y luego entrega la versión revisada lista para la revisión.

## Grafo de contexto

El contexto en Glossia es un grafo que abarca tu cuenta y tu repositorio. Las configuraciones a nivel de cuenta, como la voz y el glosario, proporcionan una línea base global, mientras que los archivos `L10N.md` colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este grafo en cada ejecución, por lo que tus instrucciones se mantienen consistentes en todos los archivos sin que tengas que repetirte. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya se ha procesado, de modo que solo el contenido cambiado o nuevo se vuelve a revisar.

## Refinamiento progresivo

Cada ciclo de revisión mejora la salida. Las correcciones retroalimentan los archivos de contexto, por lo que los errores repetidos desaparecen y la salida converge en el estándar de tu equipo con el tiempo.