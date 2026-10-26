%{
  title: "Solicitudes de traducción más tranquilas",
  summary:
    "Lo que aprendimos al soltar a Glossia en un repositorio ocupado, y cómo cambiaron las solicitudes de traducción por ello."
}
---

Aprendes mucho la primera vez que tu herramienta se encuentra con un repositorio real. Para nosotros, eso fue Tuist. Su equipo fusiona a `main` muchas veces al día, y Glossia hizo exactamente lo que habíamos construido para que hiciera: tradujo cada cambio y empujó cada archivo en cuanto estuvo listo. El resultado fue una nueva solicitud de extracción para casi cada fusión, cada una con alrededor de 150 commits, y una cola de CI llena de verificaciones que nadie había solicitado. Algunas de sus páginas de documentación también regresaron con componentes y alertas escapados a texto plano. No la experiencia tranquila, de fondo, en la que seguimos hablando.

Nos dolió porque siempre hemos dicho que el mejor sistema de traducción es aquel que no tienes que considerar. Una solicitud de extracción que inunda tu CI o destruye tu documentación es lo opuesto a eso. Así que retrocedimos y reconsideramos cómo las traducciones llegan a tu repositorio.

Ahora, Glossia mantiene una sola solicitud de extracción por proyecto y la hace crecer a medida que tu contenido cambia. Lee los archivos de bloqueo ya en esa rama, así que solo traduce lo nuevo, y empuja por lotes en lugar de archivo por archivo. En un repositorio como el de Tuist, eso son unos pocos empujes donde antes había ciento cincuenta.

También dejamos de modificar partes de tu documentación que no son nuestro problema. Glossia solía reconstruir cada página que traduciera, y cualquier cosa que no entendiera completamente, como un componente Phoenix o una alerta de GitHub, podía salir escapada. Ahora solo reemplaza las oraciones que traduce y deja todo lo demás exactamente como lo escribiste. Hubo un efecto secundario agradable que no esperábamos: porque el modelo ahora ve oraciones completas y el resto de la página, las traducciones se leen mejor. En japonés, un enlace ya no tiene que quedarse en una posición incómoda donde estaba en la oración en inglés.

Finalmente, ahora la solicitud de extracción te informa qué sucedió. Qué idiomas y archivos se tradujeron, desde qué commits, cómo calificaron, qué términos del glosario los moldearon, y qué, si algo, requiere tu atención. Lo pensamos como la nota que dejaría un colega cuidadoso antes de pedir una revisión.

Agradecemos al equipo de Tuist por su paciencia mientras lo fuimos entendiendo. Si Glossia alguna vez se interpone en tu camino de esta manera, nos encantaría escuchar al respecto.
