%{
  title: "Solicitudes de traducción más tranquilas",
  summary:
    "Lo que aprendimos al soltar a Glossia en un repositorio con alta actividad, y cómo cambiaron las solicitudes de traducción por ello."
}
---

Aprenderás mucho la primera vez que tu herramienta se encuentra con un repositorio real. Para nosotros, eso fue Tuist. Su equipo fusiona a `main` muchas veces al día, y Glossia hizo exactamente lo para lo que lo habíamos construido: tradujo cada cambio y empujó cada archivo tan pronto como estuviera listo. El resultado fue una nueva solicitud de extracción para casi cada fusión, cada una con unos 150 commits, y una cola de CI llena de comprobaciones que nadie había solicitado. Algunas de sus páginas de documentación también regresaron con componentes y alertas escapados a texto plano. No es la experiencia silenciosa y en segundo plano de la que seguimos hablando.

Fue un golpe, porque siempre hemos dicho que el mejor sistema de traducción es aquel en el que no tienes que pensar. Una solicitud de extracción que inunda tu CI o daña tu documentación es lo opuesto a eso. Así que regresamos y replanteamos cómo llegan las traducciones a tu repositorio.

Glossia ahora mantiene una sola solicitud de extracción por proyecto y la expande según cambia tu contenido. Lee los archivos de bloqueo ya presentes en esa rama, por lo que solo traduce lo nuevo, y envía los cambios por lotes en lugar de archivo por archivo. En un repositorio como el de Tuist, eso significa unos pocos envíos donde antes había ciento cincuenta.

También dejamos de tocar partes de tus documentos que no nos corresponden. Glossia antes reconstruía cada página que traducían, y cualquier cosa que no entendiera completamente, como un componente Phoenix o una alerta de GitHub, podía salir escapada en el otro lado. Ahora solo sustituye las oraciones que tradujo y deja todo lo demás exactamente como lo escribiste. Hubo un efecto secundario agradable que no esperábamos: porque ahora el modelo ve oraciones completas y el resto de la página, las traducciones se leen mejor. En japonés, un enlace ya no tiene que quedar incómodo en la posición que ocupaba en la oración en inglés.

Finalmente, la solicitud de extracción ahora te indica qué sucedió. Qué idiomas y archivos se tradujeron, desde qué commits, cómo calificaron, qué términos de glosario los formaron, y qué, si acaso, necesita tu atención. Lo pensamos como la nota que dejaría un colega cuidadoso antes de pedir una revisión.

Gracias al equipo de Tuist por su paciencia mientras resolvimos esto. Si Glossia alguna vez se pone en tu camino así, nos encantaría saber al respecto.
