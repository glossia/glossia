%{
  title: "Revisión de contenido",
  summary:
    "Mejore su contenido existente en su lugar. Glossia examina los archivos fuente para claridad, precisión y tono utilizando el contexto que proporciona, y luego produce versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan su redacción en función de la legibilidad, jerga y coherencia con la voz de su marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribirse en una ruta separada. Usted siempre controla el destino de la salida.",
      icon: "shield-check"
    },
    %{
      title: "Bucle de retroalimentación",
      description:
        "Los revisores corrigen la salida, actualizan el contexto y cada ciclo reduce la diferencia entre el borrador y la versión final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Cómo funciona la revisión

El agente lee sus archivos de origen y el gráfico de contexto, fusionando las instrucciones locales (archivos `L10N.md` en la raíz o en subdirectorios) con el contexto remoto (su voz a nivel de cuenta, terminología y configuraciones de estilo). Con el panorama completo ensamblado, reescribe el contenido para claridad, precisión y tono, luego entrega la versión revisada lista para revisión.

## Gráfico de contexto

El contexto en Glossia es un gráfico que abarca su cuenta y su repositorio. Las configuraciones a nivel de cuenta, como voz y terminología, proporcionan una línea base global, mientras que los archivos `L10N.md` colocados junto al contenido añaden sobrescrituras locales. El agente resuelve este gráfico en cada ejecución, de modo que sus instrucciones permanezcan consistentes entre archivos sin repetirse. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya ha sido procesado, de forma que solo el contenido modificado o nuevo se vuelva a revisar.

## Refinamiento progresivo

Cada ciclo de revisión mejora la salida. Las correcciones se retroalimentan en los archivos de contexto, de modo que los errores repetidos desaparezcan y la salida converja hacia el estándar de su equipo con el tiempo.