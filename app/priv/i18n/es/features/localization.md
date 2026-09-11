%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma conservando la estructura, bloques de código y formato. Los agentes de Glossia se encargan del trabajo pesado para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible a la estructura",
      description:
        "Los bloques de código, el frontmatter y el formato se mantienen intactos tras la localización. No se requiere limpieza manual.",
      icon: "código"
    },
    %{
      title: "Cualquier par de idiomas",
      description:
        "Localiza entre cualquier combinación de idiomas. Agrega nuevos destinos editando una sola línea en tu configuración.",
      icon: "Mundo"
    },
    %{
      title: "Actualizaciones incrementales",
      description:
        "Solo el contenido modificado se vuelve a localizar. Los archivos de bloqueo rastrean lo que ya ha sido procesado, ahorrando tiempo y costos.",
      icon: "Rápido"
    }
  ]
}
---
## Cómo funciona la localización

Glossia lee el contenido de tu repositorio junto con los archivos de bloqueo que rastrean lo que ya ha sido procesado. Luego combina tu contexto local (`L10N.md` files en la raíz o en subdirectorios) con el contexto global (voz, terminología y ajustes del nivel de cuenta) para construir una imagen completa de cómo debe sonar tu contenido en cada idioma objetivo. Una vez montado ese contexto, un flujo de trabajo de agentes localiza el contenido modificado mientras preserva la estructura, los bloques de código y el formato. Una vez que finaliza la ejecución, los resultados se envían de nuevo a tu repositorio como una solicitud de extracción lista para su revisión.

## Calidad impulsada por el contexto

Cada localización se beneficia del contexto que proporcionas. La terminología, las notas de estilo y las instrucciones específicas del dominio fluyen en el prompt para que el agente genere una salida que coincida con la voz de tu producto.

## Revisión con confianza

Los resultados surgen como solicitudes de extracción o archivos de borrador, listos para que tu equipo los revise. Los revisores señalan problemas, actualizan los archivos de contexto y la siguiente ejecución incorpora esas correcciones automáticamente.