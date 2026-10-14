%{
  title: "¿Por qué Glossia?",
  summary:
    "Un sistema operativo de idiomas que mantiene contenido, contexto y revisión alineados con la entrega continua.",
  category: "explicación",
  section: "translation",
  order: 1
}
---

Un producto puede lanzarse continuamente mientras sus traducciones permanecen atascadas en un ciclo de lanzamiento independiente. El contenido de origen cambia en Git, alguien lo exporta a un sistema de traducción, los editores trabajan allí y alguien importa el resultado. El producto y sus versiones de idioma divergen.

Glossia es un sistema operativo de idioma construido en torno a una premisa diferente: el trabajo lingüístico debe seguir el mismo ciclo de entrega versionado y revisable que el propio producto.

## El problema es más grande que la traducción

Los equipos necesitan preservar el significado, aplicar la terminología, adaptar el tono a la audiencia y actualizar el contenido a medida que el producto evoluciona. Esas decisiones afectan la documentación, las cadenas de interfaz de usuario, las páginas de marketing y la escritura generada por agentes de manera igual.

Un modelo puede producir un borrador útil. Por sí solo, no conoce las decisiones lingüísticas de tu organización, registra por qué cambió una frase, valida tus formatos de archivo o sincroniza la siguiente revisión de origen. Repetir un prompt no es un sistema de entrega.

Glossia combina el contexto del idioma con los mecanismos en torno a la generación: configuración, detección de cambios, validación, recuperación de fallos, historial de revisiones y revisión.

## El contenido permanece con el producto

El repositorio sigue siendo la autoridad para el contenido publicado. Los archivos de origen, la configuración, las traducciones generadas y los cambios revisables pueden viajar a través de Git y las solicitudes de extracción. Los equipos no necesitan que una interfaz de edición alojada sea la autoridad para cada oración antes de poder entregar una versión localizada.

Esto hace que los cambios de idioma sean visibles junto al cambio del producto que los motivó. Un revisor puede inspeccionar la diferencia, la CI puede validar el resultado y la misma tubería de entrega puede publicarlo.

Leia [Localización continua](./continuous-localization) para el modelo de entrega y [Propiedad del contenido](./content-ownership) para sus implicaciones de portabilidad.

## El contexto es una entrada, no una jaula

Las pautas de voz y la terminología ayudan tanto a humanos como a agentes a escribir de manera consistente. Son decisiones lingüísticas reutilizables, no solo una colección propietaria de pares de segmentos de origen-destino.

Las memorias de traducción siguen siendo útiles para las traducciones consolidadas y el contenido repetitivo. El objetivo no es descartarlas. El objetivo es evitar que el formato de memoria de un solo proveedor o el flujo de trabajo de edición sea el único lugar donde puede existir el conocimiento lingüístico de una empresa.

Vea [Memoria lingüística y memoria de traducción](./language-memory-and-translation-memory).

## La mejora es un bucle

El modelo de refinamiento progresivo de Glossia utiliza hashes de contenido para evitar el trabajo redundante, ejecuta validaciones alrededor de las transformaciones y expone fallos para que una ejecución pueda recuperarse. Las correcciones humanas pueden informar la siguiente iteración en lugar de desaparecer en una generación aislada.

La analítica de localización proporciona otra entrada: entender los idiomas y lugares donde una audiencia se sirve puede ayudar a un equipo a decidir dónde invertir. Es evidencia para la priorización, no una promesa de que una traducción generará crecimiento.

## Para quién encaja esto

Glossia es especialmente relevante cuando desarrolladores, lingüistas y equipos de productos quieren colaborar en el contenido gestionado en repositorio y publicarlo continuamente. No es una afirmación de que cada organización debe abandonar su sistema de gestión de localización existente. Un equipo cuyo requisito central sea un editor basado en navegador maduro, coordinación con agencias de traducción o una memoria consolidada grande puede preferir otro flujo de trabajo.

Las comparaciones de [Crowdin](./glossia-vs-crowdin), [Lokalise](./glossia-vs-lokalise), [Phrase](./glossia-vs-phrase) y [Weblate](./glossia-vs-weblate) explican esos compromisos.

## Implementación revisable

El código de Glossia está disponible públicamente, incluida su aplicación Phoenix, su CLI de Rust, su SDK web y su infraestructura de despliegue. Eso hace que los mecanismos del trabajo lingüístico sean inspeccionables en lugar de una caja negra.

El repositorio actualmente utiliza la [Licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite el uso y la modificación pero restringe los servicios alojados competidores. La disponibilidad pública del código fuente y las libertades de programación de licencias son distintas; lea la licencia antes de redistribuir u operar un servicio.
