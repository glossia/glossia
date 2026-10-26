%{
  title: "¿Por qué Glossia?",
  summary:
    "Un sistema operativo para idiomas que mantiene el contenido, el contexto y la revisión alineados con la entrega continua.",
  category: "explicación",
  section: "translation",
  order: 1
}
---

Un producto puede lanzarse de manera continua mientras sus traducciones permanecen atascadas en un ciclo de lanzamiento separado. Los cambios del contenido fuente ocurren en Git, alguien lo exporta a un sistema de traducción, los editores trabajan allí, y alguien importa el resultado. El producto y sus versiones de idioma se alejan entre sí.

Glossia es un sistema operativo de idiomas construido alrededor de una premisa diferente: el trabajo lingüístico debe seguir el mismo bucle de entrega versionado y revisable que el propio producto.

## ## El problema es más grande que la traducción

Los equipos necesitan preservar el significado, aplicar la terminología, coincidir con el tono de la audiencia y actualizar el contenido a medida que evoluciona el producto. Esas decisiones afectan a la documentación, las cadenas de la interfaz de usuario, las páginas de marketing y la escritura generada por los agentes por igual.

Un modelo puede producir un borrador útil. Por sí solo, no conoce las decisiones lingüísticas de tu organización, registra por qué cambió una frase, valida tus formatos de archivo o sincroniza la siguiente revisión de origen. Repetir un prompt no es un sistema de entrega.

Glossia combina el contexto de idioma con la mecánica alrededor de la generación: configuración, detección de cambios, validación, recuperación de fallos, historial de revisiones y revisión.

## ## El contenido se queda con el producto

El repositorio permanece como la autoridad para el contenido publicado. Los archivos fuente, la configuración, las traducciones generadas y los cambios revisables pueden viajar a través de Git y pull requests. Los equipos no necesitan hacer que una interfaz de edición alojada sea la autoridad para cada oración antes de poder entregar una versión localizada.

Esto hace que los cambios de idioma sean visibles junto al cambio del producto que los motivó. Un revisor puede inspeccionar el diff, la CI puede validar la salida y la misma línea de entrega puede publicarla.

Lee [Localización continua](./continuous-localization) para el modelo de entrega y [Propiedad del contenido](./content-ownership) para sus implicaciones de portabilidad.

## ## El contexto es una entrada, no una jaula

Las guías de voz y la terminología ayudan tanto a humanos como a agentes a escribir de manera consistente. Son decisiones lingüísticas reutilizables, no solo un conjunto propietario de pares de segmentos de origen-destino.

Las memorias de traducción siguen siendo útiles para traducciones establecidas y contenido repetitivo. El punto no es descartarlas. El punto es evitar hacer que el formato de memoria de un proveedor o el flujo de trabajo de edición sea el único lugar donde puede vivir el conocimiento lingüístico de una empresa.

## ## La mejora es un bucle

El modelo de refinamiento progresivo de Glossia utiliza hash de contenido para evitar trabajo redundante, ejecuta validación alrededor de las transformaciones y expone fallos para que una ejecución pueda recuperarse. Las correcciones humanas pueden informar la siguiente iteración en lugar de desaparecer en una generación aislada.

El análisis de localización proporciona otra entrada: comprender los idiomas y los lugares que usa una audiencia puede ayudar a un equipo a decidir dónde invertir. Es evidencia para la priorización, no una promesa de que una traducción producirá crecimiento.

## ## A quién va dirigido

Glossia es especialmente relevante cuando los desarrolladores, lingüistas y equipos de producto quieren colaborar en contenido gestionado por repositorio y publicarlo de manera continua. No es una afirmación de que cada organización debería abandonar su TMS existente. Un equipo cuyo requisito central sea un editor basado en el navegador maduro, la coordinación con una agencia de traducción o una memoria establecida grande puede preferir otro flujo de trabajo.

## ## Implementación inspeccionable

El código de Glossia está disponible públicamente, incluido su aplicación Phoenix, CLI de Rust, SDK web e infraestructura de despliegue. Eso hace que la mecánica del trabajo lingüístico sea inspeccionable en lugar de una caja negra.

Glossia sigue un modelo de núcleo abierto. El núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite el uso comercial, la modificación, la distribución, el autoalojamiento y los servicios alojados competidores conforme a sus términos. El código de `ee/` tiene una [licencia Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) independiente: su código es visible, pero no es de código abierto, y su uso en producción requiere un acuerdo comercial por escrito.
