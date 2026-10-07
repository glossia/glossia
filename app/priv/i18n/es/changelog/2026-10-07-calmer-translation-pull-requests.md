%{
  title: "Solicitudes de extracción de traducción más tranquilas",
  summary:
    "Lo que aprendimos al permitir que Glossia actuara libremente en un repositorio concurrido, y cómo cambiaron las solicitudes de extracción de traducción por ello."
}
---
Aprendes mucho la primera vez que tu herramienta se encuentra con un repositorio real. Para nosotros, eso fue Tuist. Su equipo fusiona hacia `main` muchas veces al día, y Glossia hizo exactamente lo para lo que se construyó: traduciría cada cambio y subiría cada archivo apenas estaba listo. El resultado fue una nueva solicitud de extracción para casi cada fusión, cada una con alrededor de 150 commits, y una cola de CI llena de comprobaciones que nadie había pedido. Algunas de sus páginas de documentación también volvían con componentes y alertas escapados a texto plano. No la experiencia silenciosa y en segundo plano de la que hablamos.

Eso fue lastimador, porque siempre habíamos dicho que el mejor sistema de traducción es aquel en el que no tienes que pensar. Una solicitud de extracción que inunda tu CI o tus documentos es lo opuesto a eso. Así que volvimos y reconsideramos cómo las traducciones llegan a tu repositorio.

Ahora Glossia mantiene una sola solicitud de extracción por proyecto y la hace crecer según cambie tu contenido. Lee los archivos de bloqueo que ya están en esa rama, así que solo traduce lo nuevo, y los envía por lotes en lugar de archivo por archivo. En un repositorio como el de Tuist, eso es un puñado de envíos donde antes había ciento cincuenta.

También dejamos de tocar partes de tus documentos que no eran nuestro deber tocar. Glossia solía reconstruir cada página que traducía, y cualquier cosa que no entendiera por completo, como un componente de Phoenix o una alerta de GitHub, podría salir al otro lado escapada. Ahora solo intercambia las frases que tradujo y deja todo lo demás exactamente como lo escribiste. Hubo un agradable efecto secundario que no esperábamos: porque el modelo ahora ve frases completas y el resto de la página, las traducciones se leen mejor. En japonés, un enlace ya no necesita estar incómodo donde estaba en la frase en inglés.

Finalmente, la solicitud de extracción ahora te dice qué ocurrió. Qué idiomas y archivos se tradujeron, de qué commits, cómo se puntuaron, qué términos de glosario las moldearon, y qué, si es que algo, necesita tu atención. Lo vemos como la nota que dejaría un colega cuidadoso antes de pedir una revisión.

Agradecemos al equipo de Tuist por su paciencia mientras entendimos esto. Si Glossia alguna vez se interpone en tu camino como esto, nos encantaría escucharlo.