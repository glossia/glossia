%{
  title: "Solicitudes de traducción más tranquilas",
  summary:
    "Lo que aprendimos al soltar a Glossia en un repositorio activo, y cómo cambiaron las solicitudes de traducción por ello."
}
---

Aprenderás mucho la primera vez que tu herramienta se encuentra con un repositorio real. Para nosotros, ese fue Tuist. Su equipo fusiona en `main` muchas veces al día, y Glossia hizo exactamente lo para lo que lo habíamos construido: tradujo cada cambio y subió cada archivo tan pronto como estuviera listo. El resultado fue una nueva solicitud de extracción para casi cada fusión, cada una con alrededor de 150 comits, y una cola de CI llena de verificaciones que nadie había pedido. Algunas de sus páginas de documentación también volvían con componentes y alertas escapadas a texto plano. No es la experiencia tranquila y de fondo de la que hemos estado hablando.

Nos dolió, porque hemos dicho siempre que el mejor sistema de traducción es aquel con el que no tienes que pensar. Una solicitud de extracción que inunda tu CI o estropea tu documentación es lo opuesto a eso. Así que volvimos atrás y reconsideramos cómo llegan las traducciones a tu repositorio.

Glossia ahora mantiene una sola solicitud de extracción por proyecto y la hace crecer conforme tu contenido cambia. Lee los archivos de bloqueo ya en esa rama, por lo que solo traduce lo nuevo, y empuja en lotes en lugar de archivos uno por uno. En un repositorio como el de Tuist, eso es un puñado de empujes donde antes había ciento cincuenta.

También dejamos de tocar partes de tu documentación que no son nuestras. Glossia solía reconstruir cada página que traduciera, y cualquier cosa que no hubiera entendido completamente, como un componente de Phoenix o una alerta de GitHub, podría salir al final escapada a texto plano. Ahora solo intercambia las oraciones que tradujo y deja todo lo demás exactamente como lo escribiste. Hubo un agradable efecto secundario que no esperábamos: porque ahora el modelo ve oraciones enteras y el resto de la página, las traducciones se leen mejor. En japonés, un enlace ya no tiene que estar torpemente donde estaba en la oración en inglés.

Finalmente, la solicitud de extracción ahora te dice qué pasó. Qué lenguajes y archivos se tradujeron, desde qué comits, cómo puntuaron, qué términos del glosario los formaron, y qué, si algo, requiere tu atención. Lo pensamos como la nota que dejaría un colega cuidadoso antes de pedir una revisión.

Gracias al equipo de Tuist por su paciencia mientras lo entendíamos. Si Glossia alguna vez te estorba de este modo, nos encantaría escuchar al respecto.
