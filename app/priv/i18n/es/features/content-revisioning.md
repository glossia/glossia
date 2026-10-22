%{
  title: "Revisión de contenido",
  summary:
    "Mejore su contenido existente directamente. Glossia revisa los archivos fuente por claridad, exactitud y tono, utilizando el contexto que proporcionas, y luego produce versiones revisadas listas para revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Tono y claridad",
      description:
        "Los agentes revisan su prosa por legibilidad, jerga y consistencia con su voz de marca.",
      icon: "message-circle"
    },
    %{
      title: "No destructivo",
      description:
        "El contenido revisado puede sobrescribir el original o escribirse en una ruta separada. Usted siempre controla el destino de salida.",
      icon: "shield-check"
    },
    %{
      title: "Bucle de retroalimentación",
      description:
        "Los revisores corrigen la salida, actualizan el contexto y, cada ciclo, reducen la brecha entre el borrador y el resultado final.",
      icon: "refresh-cw"
    }
  ]
}
---

## Cómo funciona la revisión

El agente lee tus archivos fuente y el grafo de contexto, combinando las instrucciones locales (`L10N.md` archivos en la raíz o en subdirectorios) con el contexto remoto (la voz, glosario y configuraciones de estilo a nivel de cuenta). Con el panorama completo reunido, reescribe el contenido para claridad, precisión y tono, luego genera la versión revisada lista para revisión.

## Grafo de contexto

El contexto en Glossia es un grafo que abarca tu cuenta y tu repositorio. Las configuraciones a nivel de cuenta, como la voz y el glosario, establecen una línea base global, mientras que `L10N.md` archivos colocados junto a tu contenido añaden ajustes locales. El agente resuelve este grafo en cada ejecución, por lo que tus instrucciones permanecen coherentes entre archivos sin que tengas que repetirte. Las revisiones son incrementales gracias a los archivos de bloqueo que rastrean lo que ya se ha procesado, por lo que solo el contenido cambiado o nuevo se revisita.

## Refinamiento progresivo

Cada ciclo de revisión hace que el resultado sea mejor. Las correcciones se retroalimentan en los archivos de contexto, por lo que los errores repetidos desaparecen y la salida se ajusta al estándar de tu equipo con el tiempo.
