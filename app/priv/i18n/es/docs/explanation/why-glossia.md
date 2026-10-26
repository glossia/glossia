%{
  title: "¿Por qué Glossia?",
  summary:
    "Un sistema operativo de idiomas que mantiene el contenido, el contexto y la revisión alineados con la entrega continua.",
  category: "explicación",
  section: "translation",
  order: 1
}
---

Un producto puede lanzarse continuamente mientras sus traducciones permanecen estancadas en un ciclo de publicación separado. El contenido fuente cambia en Git, alguien lo exporta a un sistema de traducción, los editores trabajan allí y alguien importa el resultado. El producto y sus versiones de idioma se desfasan.

Glossia es un sistema operativo de idiomas construido en torno a una premisa diferente: el trabajo lingüístico debe seguir el mismo bucle de entrega versionado y revisable que el producto mismo.

## El problema es más amplio que la traducción

Los equipos deben preservar el significado, aplicar la terminología, coincidir con el tono de la audiencia y actualizar el contenido a medida que el producto evoluciona. Esas decisiones afectan a la documentación, las cadenas de la IU, las páginas de marketing y los textos generados por agentes por igual.

Un modelo puede producir un borrador útil. Por sí mismo, no conoce las decisiones lingüísticas de tu organización, no registra por qué cambió una frase, no valida tus formatos de archivo, ni sincroniza la siguiente versión de origen. Repetir un prompt no es un sistema de entrega.

Glossia combina el contexto lingüístico con los mecanismos de la generación: configuración, detección de cambios, validación, recuperación de fallos, historial de revisiones y revisión.

## El contenido se mantiene con el producto

El repositorio se mantiene como la autoridad para el contenido publicado. Los archivos fuente, la configuración, las traducciones generadas y los cambios revisables pueden viajar a través de Git y las solicitudes de extracción. Los equipos no necesitan designar a una interfaz de edición alojada como autoridad para cada frase antes de poder entregar una versión localizada.

Esto hace que los cambios lingüísticos sean visibles junto al cambio del producto que los motivó. Un revisor puede inspeccionar el diff, la CI puede validar la salida y el mismo pipeline de entrega puede publicarlo.

Lee [Localización continua](./continuous-localization) para el modelo de entrega y [Propiedad del contenido](./content-ownership) para sus implicaciones de portabilidad.

## El contexto es una entrada, no una jaula

La guía de voz y la terminología ayudan tanto a humanos como a agentes a escribir de manera consistente. Son decisiones lingüísticas reutilizables, no solo una colección propietaria de pares de segmentos origen-destino.

Las memorias de traducción siguen siendo útiles para traducciones establecidas y contenido repetitivo. El punto no es descartarlas. El punto es evitar hacer que el formato de memoria de un proveedor o el flujo de trabajo de edición sean el único lugar donde el conocimiento lingüístico de una empresa puede vivir.

## La mejora es un ciclo

El modelo de refinamiento progresivo de Glossia utiliza hashes de contenido para evitar trabajo redundante, ejecuta validación alrededor de las transformaciones y expone fallos para que una ejecución se recupere. Las correcciones humanas pueden informar la siguiente iteración en lugar de desaparecer en una generación aislada.

El análisis de localización proporciona otra entrada: comprender los idiomas y lugares que utiliza una audiencia puede ayudar a un equipo a decidir dónde invertir. Es evidencia para la priorización, no una promesa de que una traducción producirá crecimiento.

## A quién le va dirigido

Glossia es especialmente relevante cuando desarrolladores, lingüistas y equipos de producto quieren colaborar en contenido gestionado desde el repositorio y公共arlo de forma continua. No es una afirmación de que cada organización debería abandonar su TMS existente. Un equipo cuya necesidad central sea un editor basado en navegador maduro, la coordinación con agencias de traducción o una gran memoria establecida puede preferir otro flujo de trabajo.

## Implementación inspeccionable

El código de Glossia está disponible públicamente, incluyendo su aplicación Phoenix, su CLI Rust, su SDK web y su infraestructura de despliegue. Esto hace que los mecanismos del trabajo lingüístico sean inspeccionables en lugar de una caja negra.

El repositorio actualmente utiliza la [licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite el uso y la modificación pero restringe los servicios alojados competidores. La disponibilidad pública del código fuente y las libertades de licenciamiento son distintas; lee la licencia antes de redistribuir o operar un servicio.
