%{
  title: "Solicitudes de integración de traducción más tranquilas",
  summary:
    "Lo que aprendimos al soltar a Glossia en un repositorio muy activo y cómo cambiaron las solicitudes de integración de traducción por ello."
}
---

Aprendes mucho la primera vez que tu herramienta se encuentra con un repositorio real. Para nosotros, eso fue Tuist. Su equipo fusiona en `main` muchas veces al día, y Glossia hizo exactamente lo que habíamos construido para que hiciera: tradujo cada cambio y empujó cada archivo tan pronto como estuvo listo. El resultado fue una nueva solicitud de extracción para casi cada fusión, cada una con alrededor de 150 commits, y una cola de CI llena de comprobaciones que nadie había pedido. Algunas de sus páginas de documentación también volvieron con componentes y alertas escapados en texto plano. No la experiencia silenciosa y de fondo de la que hemos estado hablando.

Eso fue duro, porque siempre hemos dicho que el mejor sistema de traducción es aquel que no tienes que pensar. Una solicitud de extracción que inunda tu CI o arruina tu documentación es lo contrario. Así que volvimos y replanteamos cómo llegan las traducciones a tu repositorio.

Glossia ahora mantiene una sola solicitud de extracción por proyecto y la hace crecer a medida que tu contenido cambia. Lee los archivos de bloqueo que ya están en esa rama, por lo que solo traduce lo nuevo, y empuja en partidas en lugar de archivo por archivo. En un repositorio como el de Tuist, son un par de envíos donde antes había ciento cincuenta.

También dejamos de tocar partes de tu documentación que no nos correspondía tocar. Glossia solía reconstruir cada página que traducía, y cualquier cosa que no entendiera del todo, como un componente de Phoenix o una alerta de GitHub, podía salir del otro lado escapada. Ahora solo intercambia las oraciones que traduce y deja todo lo demás exactamente como lo escribiste. Hubo un agradable efecto secundario que no esperábamos: porque el modelo ahora ve oraciones enteras y el resto de la página, las traducciones se leen mejor. En japonés, un enlace ya no tiene que sentarse incómodamente donde estaba en la oración en inglés.

Finalmente, la solicitud de extracción ahora te dice qué sucedió. Qué lenguajes y archivos se tradujeron, de qué commits, cómo se puntuaron, qué términos del glosario los moldearon y qué, si algo, requiere tu atención. La concebimos como la nota que dejaría un colega cuidadoso antes de pedirte una revisión.

Gracias al equipo de Tuist por su paciencia mientras entendíamos esto. Si Glossia se interpone en tu camino de esta manera, nos encantaría oír sobre ello.
