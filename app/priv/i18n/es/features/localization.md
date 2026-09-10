%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma preservando la estructura, los bloques de código y el formato. Los agentes de Glossia se encargan del trabajo pesado para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente de la estructura",
      description:
        "Los bloques de código, el frontmatter y el formato sobreviven a la localización intactos. No se requiere limpieza manual.",
      icon: "Código"
    },
    %{
      title: "Cualquier par de idiomas",
      description:
        "Localiza entre cualquier combinación de idiomas. Añade nuevos objetivos editando una sola línea en tu configuración.",
      icon: "Mundo"
    },
    %{
      title: "Actualizaciones incrementales",
      description:
        "Solo el contenido cambiado se vuelve a localizar. Los archivos de bloqueo rastrean lo que ya se ha procesado, ahorrando tiempo y costos.",
      icon: "Rápido"
    }
  ]
}
---
## Cómo funciona la localización

Glossia lee el contenido de tu repositorio junto con los archivos de bloqueo que rastrean lo que ya ha sido procesado. Luego, fusiona tu contexto local (archivos `L10N.md` en la raíz o en subdirectorios) con el contexto global (voz, terminología y configuraciones a nivel de cuenta) para construir una imagen completa de cómo debe sonar tu contenido en cada idioma objetivo. Una vez ensamblado dicho contexto, un flujo de trabajo de agentes localiza el contenido cambiado mientras preserva la estructura, los bloques de código y el formato. Una vez que finaliza la ejecución, los resultados se envían de vuelta a tu repositorio como una solicitud de extracción lista para revisión.

## Calidad impulsada por el contexto

Cada localización se beneficia del contexto que proporcionas. La terminología, las notas de estilo y las instrucciones específicas del dominio fluyen hacia el prompt de modo que el agente genere una salida que coincida con la voz de tu producto.

## Revisión con confianza

Las salidas se entregan como solicitudes de extracción o archivos en borrador, listas para que tu equipo las revise. Los revisores señalan problemas, actualizan archivos de contexto y la siguiente ejecución incorpora esas correcciones automáticamente.