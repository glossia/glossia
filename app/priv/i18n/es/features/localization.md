%{
  title: "Localización",
  summary:
    "Localiza tu contenido en cualquier idioma manteniendo intacta la estructura, los bloques de código y el formato. Los agentes de Glossia se encargan de la carga pesada para que tu equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "Idiomas",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible a la estructura",
      description:
        "Los bloques de código, frontmatter y formato sobreviven a la localización intactos. No se requiere limpieza manual.",
      icon: "Código"
    },
    %{
      title: "Cualquier par de idiomas",
      description:
        "Localiza entre cualquier combinación de idiomas. Añade nuevos idiomas objetivo editando una sola línea en tu configuración.",
      icon: "Globo"
    },
    %{
      title: "Actualizaciones incrementales",
      description:
        "Solo el contenido modificado se vuelve a localizar. Los archivos de bloqueo rastrean lo que ya ha sido procesado, ahorrando tiempo y costes.",
      icon: "Rayo"
    }
  ]
}
---
## Cómo funciona la localización

Glossia lee el contenido de tu repositorio junto con los archivos de bloqueo que registran lo que ya ha sido procesado. Luego combina tu contexto local (`L10N.md` archivos en la raíz o en subdirectorios) con el contexto global (voz, terminología y configuraciones a nivel de cuenta) para construir una imagen completa de cómo debe sonar tu contenido en cada idioma objetivo. Con ese contexto ensamblado, un flujo de trabajo de agente localiza el contenido modificado mientras preserva la estructura, los bloques de código y el formato. Una vez que la ejecución termina, los resultados se envían de nuevo a tu repositorio como una solicitud de extracción lista para revisión.

## Calidad impulsada por el contexto

Cada localización se beneficia del contexto que proporcionas. La terminología, las notas de estilo y las instrucciones específicas del dominio todo fluye en el prompt para que el agente genere una salida que coincida con la voz de tu producto.

## Revisa con confianza

Los resultados aparecen como solicitudes de extracción o archivos en borrador, listos para que tu equipo los revise. Los revisores señalan problemas, actualizan los archivos de contexto y la siguiente ejecución incorpora automáticamente esas correcciones.