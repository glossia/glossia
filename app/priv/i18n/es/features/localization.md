%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma manteniendo la estructura, bloques de código y el formato. Los agentes de Glossia se encargan del trabajo pesado para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible a la estructura",
      description:
        "Los bloques de código, frontmatter y el formato sobreviven a la localización intactos. No se requiere limpieza manual.",
      icon: "código"
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

Glossia lee el contenido desde tu repositorio junto con los archivos de bloqueo que rastrean lo que ya se ha procesado. Luego fusiona tu contexto local (`L10N.md` archivos en la raíz o en subdirectorios) con el contexto global (voz, glosario y configuraciones a nivel de cuenta) para construir una imagen completa de cómo debe sonar tu contenido en cada idioma objetivo. Con ese contexto ensamblado, un flujo de trabajo de agentes localiza el contenido cambiado mientras preserva la estructura, los bloques de código y el formato. Una vez que finaliza la ejecución, los resultados se envían de nuevo a tu repositorio como una solicitud de extracción lista para revisión.

## Calidad impulsada por el contexto

Cada localización se beneficia del contexto que proporcionas. El glosario, las notas de estilo y las instrucciones específicas de dominio fluyen hacia el prompt para que el agente produzca una salida que coincida con la voz de tu producto.

## Revisión con confianza

Los resultados llegan como solicitudes de extracción o archivos en borrador, listos para que tu equipo los revise. Los revisores señalan problemas, actualizan los archivos de contexto y la siguiente ejecución incorpora esas correcciones automáticamente.
