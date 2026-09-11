%{
  title: "Revisión del contenido",
  summary:
    "Mejore su contenido existente en su lugar. Glossia revisa los archivos de origen en busca de claridad, precisión y tono utilizando el contexto que usted proporciona, y luego produce versiones revisadas listas para su revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan su texto en busca de legibilidad, jerga y coherencia con su voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribirse en una ruta separada. Usted siempre controla el destino de salida.",
      icon: "shield-check"
    },
    %{
      title: "Ciclo de retroalimentación",
      description:
        "Los revisores corrigen la salida, actualizan el contexto y cada ciclo reduce la brecha entre el borrador y el final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona la revisión

El agente lee tus archivos fuente y el gráfico de contexto, fusionando las instrucciones locales (archivos `L10N.md` en la raíz o en subdirectorios) con el contexto remoto (tus configuraciones de voz, terminología y estilo a nivel de cuenta). Con toda la información reunida, reescribe el contenido para mejorar la claridad, precisión y tono, y luego genera la versión revisada lista para la revisión.

## Gráfico de contexto

El contexto en Glossia es un gráfico que abarca tu cuenta y tu repositorio. Las configuraciones a nivel de cuenta, como la voz y la terminología, proporcionan una base global, mientras que los archivos `L10N.md` colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este gráfico con cada ejecución, para que tus instrucciones permanezcan coherentes entre archivos sin que tengas que repetirlas tú mismo. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya ha sido procesado, por lo que solo el contenido cambiado o nuevo se vuelve a procesar.

## Refinamiento progresivo

Cada ciclo de revisión mejora la salida. Las correcciones retroalimentan los archivos de contexto, para que los errores repetidos desaparezcan y la salida converja hacia el estándar de tu equipo con el tiempo.