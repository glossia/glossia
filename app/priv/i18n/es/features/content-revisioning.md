%{
  title: "Revisión de contenido",
  summary: "Mejore su contenido existente en el mismo lugar. Glossia revisa los archivos de origen para comprobar su claridad, precisión y tono utilizando el contexto que proporcione y, a continuación, genera versiones revisadas listas para su revisión.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Tono y claridad", description: "Los agentes revisan la legibilidad de sus textos, el uso de jerga y la coherencia con la voz de su marca.", icon: "message-circle"},
    %{title: "No destructivo", description: "El contenido revisado puede sobrescribir el original o escribirse en una ruta independiente. Usted siempre controla el destino de salida.", icon: "shield-check"},
    %{title: "Ciclo de retroalimentación", description: "Los revisores corrigen el resultado y actualizan el contexto; cada ciclo reduce la diferencia entre el borrador y la versión final.", icon: "refresh-cw"}
  ]
}
---
## Cómo funciona el control de revisiones

El agente lee los archivos fuente y el grafo de contexto, y combina las instrucciones locales (archivos `GLOSSIA.md` en la raíz o en subdirectorios) con el contexto remoto (la voz, la terminologia y la configuración de estilo de su cuenta). Tras recopilar toda la información, reescribe el contenido para mejorar su claridad, precisión y tono, y genera la versión revisada lista para su revisión.

## Grafo de contexto

El contexto de Glossia es un grafo que abarca su cuenta y su repositorio. La configuración de la cuenta, como la voz y la terminologia, proporciona una base global, mientras que los archivos `GLOSSIA.md` ubicados junto al contenido añaden ajustes locales. El agente resuelve este grafo en cada ejecución, por lo que las instrucciones se mantienen coherentes entre archivos sin necesidad de repetirlas. Las revisiones son incrementales gracias a los archivos de bloqueo, que registran lo que ya se ha procesado. De este modo, solo se revisa el contenido nuevo o modificado.

## Refinamiento progresivo

Cada ciclo de revisión mejora el resultado. Las correcciones se incorporan a los archivos de contexto, por lo que los errores recurrentes desaparecen y el resultado converge con el tiempo hacia el estándar de su equipo.