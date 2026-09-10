%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente directamente. Glossia revisa los archivos fuente para claridad, precisión y tono utilizando el contexto que proporcionas, y genera versiones revisadas listas para su revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan tu redacción para legibilidad, jerga y coherencia con tu voz de marca.",
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
        "Los revisores corrigen el resultado, actualizan el contexto y cada ciclo reduce la diferencia entre el borrador y el final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona la revisión

El agente lee tus archivos fuente y el grafo de contexto, combinando las instrucciones locales (`L10N.md` en la raíz o subdirectorios) con el contexto remoto (tus ajustes de voz, terminología y estilo a nivel de cuenta). Con toda la información reunida, reescribe el contenido para mejorar la claridad, la precisión y el tono, y luego genera la versión revisada lista para revisión.

## Grafo de contexto

El contexto en Glossia es un grafo que abarca tu cuenta y tu repositorio. Los ajustes a nivel de cuenta, como voz y terminología, establecen una línea base global, mientras que los archivos `L10N.md` colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este grafo en cada ejecución, de modo que tus instrucciones permanezcan coherentes entre los archivos sin que tengas que repetirte. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya ha sido procesado, de modo que solo el contenido modificado o nuevo se vuelve a revisar.

## Refinamiento progresivo

Cada ciclo de revisión mejora el resultado. Las correcciones se retroalimentan en los archivos de contexto, por lo que los errores repetidos desaparecen y el resultado converge en el estándar de tu equipo con el tiempo.