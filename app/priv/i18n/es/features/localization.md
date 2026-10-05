%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma mientras preservas la estructura, los bloques de código y el formato. Los agentes de Glossia se encargan del trabajo pesado para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "idiomas",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible a la estructura",
      description:
        "Los bloques de código, el frontmatter y el formato sobreviven a la localización intactos. No se requiere limpieza manual.",
      icon: "código"
    },
    %{
      title: "Cualquier par de idiomas",
      description:
        "Localiza entre cualquier combinación de idiomas. Añade nuevos objetivos editando una sola línea en tu configuración.",
      icon: "globo"
    },
    %{
      title: "Actualizaciones incrementales",
      description:
        "Solo el contenido cambiado se vuelve a localizar. Los archivos de bloqueo registran lo que ya ha sido procesado, ahorrando tiempo y costo.",
      icon: "zap"
    }
  ]
}
---
## Cómo funciona la localización

Glossia lee el contenido de su repositorio junto con los archivos de bloqueo que rastrean lo que ya ha sido procesado. A continuación, fusiona su contexto local (archivos `L10N.md` en la raíz o en subdirectorios) con el contexto global (voz, glosario y configuraciones a nivel de cuenta) para crear una visión completa de cómo debe sonar su contenido en cada idioma objetivo. Con ese contexto ensamblado, un flujo de trabajo con agentes localiza el contenido modificado mientras preserva la estructura, los bloques de código y el formato. Una vez que finaliza la ejecución, los resultados se envían de vuelta a su repositorio como una solicitud de extracción lista para la revisión.

## Calidad basada en el contexto

Cada localización se beneficia del contexto que usted proporciona. El glosario, las notas de estilo y las instrucciones específicas del dominio fluyen hacia el prompt para que el agente genere un resultado que coincida con la voz de su producto.

## Revisión con confianza

Los resultados se convierten en solicitudes de extracción o archivos en borrador, listos para que su equipo los revise. Los revisores señalan problemas, actualizan los archivos de contexto y la próxima ejecución incorpora esas correcciones automáticamente.