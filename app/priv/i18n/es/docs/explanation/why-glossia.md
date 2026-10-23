%{
  title: "¿Por qué Glossia?",
  summary:
    "Un sistema operativo para idiomas que mantiene el contenido, el contexto y la revisión alineados con la entrega continua.",
  category: "explicación",
  section: "translation",
  order: 1
}
---

Un producto puede lanzarse de forma continua mientras sus traducciones permanecen estancadas en un ciclo de lanzamiento separado. El contenido fuente cambia en Git, alguien lo exporta a un sistema de traducción, los editores trabajan allí y alguien importa el resultado. El producto y sus versiones de idioma se alejan.

Glossia es un Sistema operativo de idioma construido alrededor de una premisa diferente: el trabajo de idioma debe seguir el mismo ciclo de entrega versionado y revisable que el producto en sí.

## El problema es más amplio que la traducción

Los equipos deben preservar el significado, aplicar terminología, coincidir con el tono de la audiencia y actualizar el contenido mientras el producto evoluciona. Esas decisiones afectan a la documentación, cadenas de la interfaz de usuario, páginas de marketing y toda escritura generada por agente.

Un modelo puede producir un borrador útil. Por sí mismo, no conoce las decisiones de idioma de su organización, registra por qué cambió una frase, valida sus formatos de archivo o sincroniza la próxima revisión de la fuente. Repetir una indicación no es un sistema de entrega.

Glossia combina el contexto de idioma con la mecánica alrededor de la generación: configuración, detección de cambios, validación, recuperación de fallos, historial de revisiones y revisión.

## El contenido permanece con el producto

El repositorio sigue siendo la autoridad para el contenido publicado. Los archivos fuente, la configuración, las traducciones generadas y los cambios revisables pueden viajar a través de Git y las solicitudes de extracción. Los equipos no necesitan hacer de una interfaz de edición alojada la autoridad para cada oración antes de poder entregar una versión localizada.

Esto hace que los cambios de idioma sean visibles junto al cambio de producto que los motivó. Una revisora puede inspeccionar el diff, CI puede validar la salida y el mismo pipeline de entrega puede publicarlo.

Lea [Localización continua](./continuous-localization) para el modelo de entrega y [Propiedad del contenido](./content-ownership) para sus implicaciones de portabilidad.

## El contexto es una entrada, no una jaula

La orientación por voz y la terminología ayudan tanto a humanos como a agentes a escribir consistentemente. Son decisiones de idioma reutilizables, no solo una colección propietaria de pares de segmentos origen-destino.

Las memorias de traducción siguen siendo útiles para traducciones establecidas y contenido repetitivo. El punto no es desecharlas. El punto es evitar hacer el formato de memoria de un proveedor o el flujo de trabajo de edición el único lugar donde puede vivir el conocimiento de idioma de una empresa.

## La mejora es un bucle

El modelo de refinamiento progresivo de Glossia utiliza hashes de contenido para evitar trabajo redundante, ejecuta validación alrededor de transformaciones y expone fallos para que una ejecución pueda recuperarse. Las correcciones humanas pueden informar la siguiente iteración en lugar de desaparecer en una generación aislada.

El análisis de localización proporciona otra entrada: comprender los idiomas y lugares que utiliza una audiencia puede ayudar a un equipo a decidir dónde invertir. Es evidencia para la priorización, no una promesa de que una traducción producirá crecimiento.

## Para quién es adecuado

Glossia es especialmente relevante cuando desarrolladores, lingüistas y equipos de producto desean colaborar en contenido gestionado por repositorio y lanzarlo de forma continua. No es una afirmación de que cada organización deba abandonar su TMS existente. Un equipo cuyo requisito central sea un editor basado en navegador maduro, coordinación con agencia de traducción o una gran memoria establecida podría preferir otro flujo de trabajo.

## Implementación revisable

El código de Glossia está disponible públicamente, incluido su aplicación Phoenix, su CLI en Rust, su SDK web e infraestructura de despliegue. Eso hace que la mecánica del trabajo de idioma sea revisable en lugar de una caja negra.

El repositorio actualmente utiliza la [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite el uso y la modificación pero restringe los servicios alojados competidores. La disponibilidad pública del código fuente y las libertades de licencia son distintas; lea la licencia antes de redistribuir u operar un servicio.
