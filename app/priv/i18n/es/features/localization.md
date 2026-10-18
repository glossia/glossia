%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma mientras mantienes la estructura, los bloques de código y el formato. Los agentes de Glossia manejan la carga pesada para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Consciente de la estructura",
      description:
        "Los bloques de código, el frontmatter y el formato sobreviven intactos a la localización. No se requiere limpieza manual.",
      icon: "Código"
    },
    %{
      title: "Cualquier par de idiomas",
      description:
        "Localiza entre cualquier combinación de idiomas. Añade nuevos objetivos editando una sola línea en tu config.",
      icon: "Mundo"
    },
    %{
      title: "Actualizaciones incrementales",
      description:
        "Solo el contenido modificado se vuelve a localizar. Los archivos de bloqueo rastrean lo que ya se ha procesado, ahorrando tiempo y costos.",
      icon: "Rápido"
    }
  ]
}
---

## Cómo funciona la localización

Glossia lee el contenido de tu repositorio junto con los archivos de bloqueo que rastrean lo que ya ha sido procesado. Luego fusiona tu contexto local ( `L10N.md` archivos en la raíz o en subdirectorios) con el contexto global (voz, glosario y ajustes a nivel de cuenta) para construir una imagen completa de cómo debe sonar tu contenido en cada idioma de destino. Con ese contexto ensamblado, un flujo de trabajo de agentes localiza el contenido modificado mientras se preserva la estructura, los bloques de código y el formato. Una vez que la ejecución se completa, los resultados se envían de nuevo a tu repositorio como una solicitud de extracción lista para la revisión.

## Calidad impulsada por el contexto

Cada localización se beneficia del contexto que proporcionas. El glosario, las notas de estilo y las instrucciones específicas del dominio fluyen en la indicación para que el agente genere una salida que coincida con la voz de tu producto.

## Revisa con confianza

Los resultados se envían como solicitudes de extracción o archivos en borrador, listos para que tu equipo los revise. Los revisores señalan problemas, actualizan archivos de contexto y la próxima ejecución incorpora esas correcciones automáticamente.
