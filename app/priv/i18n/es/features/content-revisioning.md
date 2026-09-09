%{
  title: "Revisión de contenido",
  summary:
    "Mejora tu contenido existente en su sitio. Glossia revisa los archivos fuente por claridad, precisión y tono utilizando el contexto que proporcionas, luego produce versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan tu redacción por legibilidad, jerga y coherencia con la voz de tu marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribir en una ruta separada. Siempre controlas el destino de salida.",
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

El agente lee tus archivos de origen y el gráfico de contexto, fusionando las instrucciones locales (`L10N.md` archivos en la raíz o en subdirectorios) con el contexto remoto (tus ajustes de voz, terminología y estilo a nivel de cuenta). Una vez ensamblado el panorama completo, reescribe el contenido para claridad, precisión y tono, y luego entrega la versión revisada lista para revisión.

## Gráfico de contexto

El contexto en Glossia es un gráfico que abarca tu cuenta y tu repositorio. Ajustes a nivel de cuenta como la voz y la terminología proporcionan una línea base global, mientras que los archivos `L10N.md` colocados junto a tu contenido añaden sobrescrituras locales. El agente resuelve este gráfico en cada ejecución, por lo que tus instrucciones permanecen consistentes entre archivos sin que tengas que repetirte. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya ha sido procesado, por lo que solo se vuelven a examinar el contenido cambiado o nuevo.

## Refinamiento progresivo

Cada ciclo de revisión mejora el resultado. Las correcciones se retroalimentan en los archivos de contexto, por lo que los errores repetidos desaparecen y el resultado converge en el estándar de tu equipo con el tiempo.