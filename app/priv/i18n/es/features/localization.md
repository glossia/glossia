%{
  title: "Localización",
  summary: "Localice su contenido a cualquier idioma conservando la estructura, los bloques de código y el formato. Los agentes de Glossia se encargan del trabajo pesado para que su equipo pueda centrarse en la revisión.",
  order: 1,
  icon: "languages",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Respeta la estructura", description: "Los bloques de código, el frontmatter y el formato permanecen intactos durante la localización. No se requiere ninguna limpieza manual.", icon: "code"},
    %{title: "Cualquier par de idiomas", description: "Localice contenido entre cualquier combinación de idiomas. Añada nuevos idiomas de destino editando una sola línea de la configuración.", icon: "globe"},
    %{title: "Actualizaciones incrementales", description: "Solo se vuelve a localizar el contenido modificado. Los archivos de bloqueo registran lo que ya se ha procesado, lo que ahorra tiempo y costes.", icon: "zap"}
  ]
}
---
## Cómo funciona la localización

Glossia lee el contenido de su repositorio junto con los archivos de bloqueo que registran lo que ya se ha procesado. A continuación, combina su contexto local (archivos `GLOSSIA.md` en la raíz o en subdirectorios) con el contexto global (voz, terminologia y configuración de la cuenta) para obtener una visión completa de cómo debe sonar su contenido en cada idioma de destino. Una vez reunido ese contexto, un flujo de trabajo basado en agentes localiza el contenido modificado y conserva la estructura, los bloques de código y el formato. Cuando finaliza la ejecución, los resultados se envían a su repositorio como una pull request lista para revisión.

## Calidad basada en el contexto

Cada localización se beneficia del contexto que usted proporciona. La terminologia, las indicaciones de estilo y las instrucciones específicas del dominio se incorporan al prompt para que el agente genere un resultado acorde con la voz de su producto.

## Revise con confianza

Los resultados se entregan como pull requests o archivos de borrador, listos para que su equipo los revise. Los revisores señalan problemas, actualizan los archivos de contexto y la siguiente ejecución incorpora esas correcciones automáticamente.