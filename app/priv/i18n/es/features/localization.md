%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma preservando la estructura, bloques de código y formato. Los agentes de Glossia realizan el trabajo pesado para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente de la estructura",
      description:
        "Bloques de código, frontmatter y formato sobreviven intactos tras la localización. No se requiere limpieza manual.",
      icon: "Código"
    },
    %{
      title: "Cualquier par de idiomas",
      description:
        "Localiza entre cualquier combinación de idiomas. Añade nuevas metas editando una sola línea en tu configuración.",
      icon: "Mundo"
    },
    %{
      title: "Actualizaciones incrementales",
      description:
        "Solo el contenido modificado se vuelve a localizar. Los archivos de bloqueo rastrean lo que ya ha sido procesado, ahorrando tiempo y costos.",
      icon: "Zap"
    }
  ]
}
---
## Cómo funciona la localización

Glossia lee el contenido de tu repositorio junto con los archivos de bloqueo que rastrean lo que ya ha sido procesado. Luego fusiona tu contexto local (`GLOSSIA.md` archivos en la raíz o en subdirectorías) junto con el contexto global (voz, terminología y configuraciones a nivel de cuenta) para construir una imagen completa de cómo tu contenido debería sonar en cada idioma objetivo. Con ese contexto montado, un flujo de trabajo por agentes localiza el contenido modificado mientras preserva la estructura, los bloques de código y el formato. Una vez que se completa la ejecución, los resultados se envían de nuevo a tu repositorio como una solicitud pull lista para revisión.

## Calidad impulsada por contexto

Cada localización se beneficia del contexto que proporcionas. La terminología, las notas de estilo y las instrucciones específicas del dominio fluyen al prompt para que el agente produzca una salida que coincida con la voz de tu producto.

## Revisión con confianza

Las salidas se depositan como solicitudes pull o archivos en borrador, listos para que tu equipo las revise. Los revisores marcan problemas, actualizan archivos de contexto y la siguiente ejecución incorpora esas correcciones automáticamente.