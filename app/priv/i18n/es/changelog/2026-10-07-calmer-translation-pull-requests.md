%{
  title: "Solicitudes de traducción más tranquilas",
  summary:
    "Lo que aprendimos al soltar a Glossia en un repositorio con alta actividad, y cómo cambiaron las solicitudes de traducción por ello."
}
---

Aprende mucho la primera vez que tu herramienta se encuentra con un repositorio real. Para nosotros, eso fue Tuist. Su equipo fusiona en `main` muchas veces al día, y Glossia hizo exactamente lo que hemos construido para que hiciera: tradujo cada cambio y subió cada archivo apenas estuvo listo. El resultado fue una nueva solicitud de extracción para casi cada fusión, cada una con alrededor de 150 commits, y una cola de CI llena de verificaciones que nadie había solicitado. Algunas de sus páginas de documentación también volvieron con componentes y alertas escapadas a texto plano. No la experiencia silenciosa y de fondo de la que seguimos hablando.

Eso resultó doloroso, porque siempre hemos dicho que el mejor sistema de traducción es aquel en el que no necesitas pensar. Una solicitud de extracción que inunde tu CI o dañe tu documentación es lo opuesto a eso. Así que volvimos y repensamos cómo llegan las traducciones a tu repositorio.

Glossia ahora mantiene una única solicitud de extracción por proyecto y la hace crecer conforme cambia tu contenido. Lee los archivos de bloqueo ya en esa rama, por lo que solo traduce lo nuevo y empuja en lotes en lugar de archivo por archivo. En un repositorio como el de Tuist, eso son unos pocos envíos donde antes había ciento cincuenta.

También dejamos de tocar partes de tu documentación que no nos correspondía tocar. Glossia solía reconstruir cada página que traducía, y cualquier elemento que no entendiera completamente, como un componente Phoenix o una alerta de GitHub, podía salir al otro lado escapado. Ahora solo cambia las frases que tradujo y deja todo lo demás exactamente como lo escribiste. Hubo un efecto secundario agradable que no esperábamos: porque ahora el modelo ve oraciones completas y el resto de la página, las traducciones se leen mejor. En japonés, un enlace ya no tiene que posicionarse incómodamente donde estaba en la frase en inglés.

Finalmente, la solicitud de extracción ahora te dice qué sucedió. Qué idiomas y archivos se tradujeron, desde qué commits, cómo puntuaron, qué términos del glosario los conformaron y qué, si algo, requiere tu atención. Nosotros la vemos como la nota que dejaría un colega atento antes de pedir una revisión.

Gracias al equipo de Tuist por su paciencia mientras lo resolvíamos. Si Glossia se pone en su camino de esta manera, nos encantaría escuchar sobre ello.
