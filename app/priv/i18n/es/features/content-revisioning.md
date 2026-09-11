%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente en su lugar. Glossia revisa los archivos fuente por claridad, precisión y tono utilizando el contexto que proporcionas, luego produce versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan tu texto por legibilidad, jerga y coherencia con tu voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribir en una ruta separada. Siempre controlas el destino de la salida.",
      icon: "shield-check"
    },
    %{
      title: "Bucle de retroalimentación",
      description:
        "Los revisores corrigen la salida, actualizan el contexto y cada ciclo estrecha la brecha entre el borrador y la versión final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona la revisión

El agente lee tus archivos fuente y el grafo de contexto, fusionando las instrucciones locales (archivos `L10N.md` en la raíz o en subdirectorías) con el contexto remoto (tus preferencias de voz, terminología y estilo a nivel de cuenta). Con el panorama completo ensamblado, reescribe el contenido para la claridad, precisión y tono, y luego exporta la versión revisada lista para su revisión.

## Grafo de contexto

El contexto en Glossia es un grafo que abarca tu cuenta y tu repositorio. Las configuraciones a nivel de cuenta, como la voz y la terminología, establecen una base global, mientras que los archivos `L10N.md` colocados junto a tu contenido introducen sobrescrituras locales. El agente resuelve este grafo en cada ejecución, para que tus instrucciones permanezcan consistentes entre archivos sin que tengas que repetirte. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo ya procesado, de modo que solo el contenido modificado o nuevo se vuelve a procesar.

## Refinamiento progresivo

Cada ciclo de revisión mejora el resultado. Las correcciones se retroalimentan en los archivos de contexto, de modo que los errores repetidos desaparecen y el resultado converge hacia el estándar de tu equipo con el tiempo.