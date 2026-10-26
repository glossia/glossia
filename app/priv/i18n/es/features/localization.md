%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma mientras se preserva la estructura, los bloques de código y el formato. Los agentes de Glossia asumen el trabajo pesado para que tu equipo se centre en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible a la estructura",
      description:
        "Los bloques de código, el frontmatter y el formato se preservan intactos tras la localización. No se requiere limpieza manual.",
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
        "Solo el contenido modificado se vuelve a localizar. Los archivos de bloqueo rastrean lo que ya ha sido procesado, ahorrando tiempo y costes.",
      icon: "Rápido"
    }
  ]
}
---

## Cómo funciona la localización

Glossia lee el contenido de tu repositoriojunto con archivos de bloqueo que rastrean lo que ya ha sido procesado. Luego fusiona tu contexto local (`L10N.md` archivos en la raíz o en subdirectorios) con el contexto global (voz, glosario y configuraciones a nivel de cuenta) para construir una imagen completa de cómo debe sonar tu contenido en cada idioma objetivo. Con ese contexto ensamblado, un flujo de trabajo con agente localiza el contenido modificado mientras preserva la estructura, los bloques de código y el formato. Una vez que finaliza la ejecución, los resultados se envían de vuelta a tu repositorio como una solicitud de extracción lista para revisión.

## Calidad impulsada por el contexto

Toda localización se beneficia del contexto que proporcionas. El glosario, las notas de estilo y las instrucciones específicas del dominio fluyen hacia el prompt para que el agente produzca una salida que coincida con la voz de tu producto.

## Revisión con confianza

Las salidas aparecen como solicitudes de extracción o archivos en borrador, listos para que tu equipo revise. Los revisores señalan problemas, actualizan archivos de contexto y la próxima ejecución incorpora esas correcciones automáticamente.
