%{
  title: "¿Por qué Glossia?",
  summary:
    "Un sistema operativo para idiomas que mantiene el contenido, el contexto y la revisión alineados con la entrega continua.",
  category: "Explicación",
  section: "translation",
  order: 1
}
---

Un producto puede lanzarse de forma continua mientras sus traducciones permanezcan atascadas en un ciclo de lanzamiento separado. El contenido fuente cambia en Git, alguien lo exporta a un sistema de traducción, los editores trabajan allí y alguien importa el resultado. El producto y sus versiones de idioma se separan con el tiempo.

Glossia es un sistema operativo del lenguaje construido en torno a un principio distinto: el trabajo lingüístico debe seguir el mismo ciclo de entregas versionado y revisable que el propio producto.

## El problema es más amplio que la traducción

Los equipos necesitan preservar el significado, aplicar la terminología, adaptar el tono del público objetivo y actualizar el contenido a medida que el producto evoluciona. Esas decisiones afectan a la documentación, las cadenas de la interfaz de usuario, las páginas de marketing y el texto generado por agentes por igual.

Un modelo puede producir un borrador útil. Por sí solo, no conoce las decisiones lingüísticas de su organización, registra por qué cambió una frase, valida sus formatos de archivo o sincroniza la siguiente revisión del origen. Repetir una indicación no es un sistema de entrega.

Glossia combina el contexto lingüístico con los mecanismos alrededor de la generación: configuración, detección de cambios, validación, recuperación de fallos, historial de revisiones y revisión.

## El contenido permanece con el producto

El repositorio permanece la autoridad para el contenido publicado. Los archivos fuente, la configuración, las traducciones generadas y los cambios revisables pueden circular a través de Git y las solicitudes de extracción. Los equipos no necesitan hacer de una interfaz de edición alojada la autoridad para cada oración antes de poder publicar un lanzamiento localizado.

Esto hace que los cambios lingüísticos sean visibles junto al cambio del producto que los motivó. Un revisor puede inspeccionar el diff, CI puede validar la salida y el mismo flujo de entrega puede publicarla.

Lea [Localización continua](./continuous-localization) para el modelo de entrega y [Propiedad del contenido](./content-ownership) para sus implicaciones de portabilidad.

## El contexto es una entrada, no una jaula

La guía de voz y la terminología ayudan tanto a humanos como a agentes a escribir de manera consistente. Son decisiones lingüísticas reutilizables, no solo una colección propietaria de pares de segmentos fuente-destino.

Las memorias de traducción siguen siendo útiles para las traducciones establecidas y el contenido repetitivo. El objetivo no es descartarlas. El objetivo es evitar hacer el formato de memoria o el flujo de edición de un proveedor el único lugar donde el conocimiento lingüístico de una empresa pueda residir.

Consulte [Memoria lingüística y memoria de traducción](./language-memory-and-translation-memory).

## La mejora es un ciclo

El modelo de refinamiento progresivo de Glossia utiliza hashes de contenido para evitar trabajo redundante, ejecuta validación alrededor de transformaciones y expone fallos para que una ejecución pueda recuperarse. Las correcciones humanas pueden informar la siguiente iteración en lugar de desaparecer en una generación aislada.

El análisis de localización proporciona otra entrada: comprender los idiomas y lugares que utiliza un público puede ayudar a un equipo a decidir dónde invertir. Es evidencia para la priorización, no una promesa de que una traducción producirá crecimiento.

## ¿A quién le sirve?

Glossia es especialmente relevante cuando desarrolladores, lingüistas y equipos de producto desean colaborar en contenido gestionado por repositorio y publicarlo de forma continua. No es un reclamo de que cada organización deba abandonar su TMS existente. Un equipo cuyo requisito central sea un editor basado en navegador maduro, la coordinación con una agencia de traducción o una memoria grande y establecida podría preferir otro flujo.

Las comparaciones de [Crowdin](./glossia-vs-crowdin), [Lokalise](./glossia-vs-lokalise), [Phrase](./glossia-vs-phrase) y [Weblate](./glossia-vs-weblate) explican esos compromisos.

## Implementación inspeccionable

El código de Glossia está disponible públicamente, incluida su aplicación Phoenix, el CLI de Rust, el SDK web y la infraestructura de implementación. Eso hace que los mecanismos del trabajo lingüístico sean inspeccionables en lugar de una caja negra.

El repositorio actualmente utiliza la [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md), lo que permite su uso y modificación pero restringe los servicios alojados competidores. La disponibilidad del código fuente público y las libertades de licencia son distintas; lea la licencia antes de redistribuir o operar un servicio.
