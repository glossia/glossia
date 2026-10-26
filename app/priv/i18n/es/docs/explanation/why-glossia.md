%{
  title: "¿Por qué Glossia?",
  summary:
    "Un sistema operativo de idiomas que mantiene contenido, contexto y revisión alineados con entrega continua.",
  category: "explicación",
  section: "translation",
  order: 1
}
---

Un producto puede lanzarse continuamente mientras sus traducciones permanecen atrapadas en un ciclo de lanzamiento separado. El contenido fuente cambia en Git, alguien lo exporta a un sistema de traducción, los editores trabajan allí, y alguien importa el resultado. El producto y sus versiones del idioma divergen.

Glossia es un sistema operativo para el idioma construido alrededor de una premisa diferente: el trabajo lingüístico debe seguir el mismo ciclo de entrega versionado y revisable que el propio producto.

## El problema es más grande que la traducción

Los equipos deben preservar el significado, aplicar la terminología, adaptar el tono a la audiencia y actualizar el contenido a medida que evoluciona el producto. Esas decisiones afectan a la documentación, las cadenas de la interfaz de usuario, las páginas de marketing y la redacción generada por agentes por igual.

Un modelo puede producir un borrador útil. Sin embargo, por sí solo, no conoce las decisiones lingüísticas de su organización, registra por qué cambió una frase, valida los formatos de archivo ni sincroniza la siguiente revisión de fuente. Repetir una instrucción no es un sistema de entrega.

Glossia combina el contexto lingüístico con los mecanismos en torno a la generación: configuración, detección de cambios, validación, recuperación ante fallos, historial de revisiones y revisión.

## El contenido permanece con el producto

El repositorio sigue siendo la autoridad para el contenido publicado. Los archivos fuente, la configuración, las traducciones generadas y los cambios sujetos a revisión pueden viajar a través de Git y las pull requests. Los equipos no necesitan designar una interfaz de edición alojada como autoridad para cada frase antes de poder lanzar una versión localizada.

Esto hace que los cambios lingüísticos sean visibles junto al cambio del producto que los motivó. Un revisor puede inspeccionar las diferencias, CI puede validar la salida y el mismo pipeline de entrega puede publicarla.

Lea [localización continua](./continuous-localization) para el modelo de entrega y [Propiedad del contenido](./content-ownership) para sus implicaciones de portabilidad.

## El contexto es una entrada, no una jaula

La orientación de voz y la terminología ayudan tanto a los humanos como a los agentes a escribir de manera consistente. Son decisiones lingüísticas reutilizables, no solo una colección propietaria de pares de segmentos de origen a destino.

Las memorias de traducción siguen siendo útiles para las traducciones consolidadas y el contenido repetitivo. No se trata de descartarlas. Se trata de evitar que el formato de memoria de un proveedor específico o el flujo de trabajo de edición sea el único lugar en el que el conocimiento lingüístico de una empresa pueda residir.

## La mejora es un ciclo

El modelo de refinamiento progresivo de Glossia utiliza hashes de contenido para evitar trabajo redundante, ejecuta validaciones en las transformaciones y expone fallos para que una ejecución pueda recuperarse. Las correcciones humanas pueden informar la siguiente iteración en lugar de desaparecer en una generación aislada.

El análisis de localización ofrece otra entrada: comprender los idiomas y los lugares que utiliza una audiencia puede ayudar a un equipo a decidir dónde invertir. Es evidencia para la priorización, no una promesa de que una traducción generará crecimiento.

## A quién le conviene

Glossia es especialmente relevante cuando los desarrolladores, los lingüistas y los equipos de producto desean colaborar en el contenido administrado por repositorio y lanzarlo continuamente. No se afirma que cada organización deba abandonar su TMS existente. Un equipo cuya necesidad central sea un editor maduro basado en el navegador, la coordinación con agencias de traducción o una memoria consolidada grande puede preferir otro flujo de trabajo.

## Implementación inspeccionable

El código de Glossia está disponible públicamente, incluida su aplicación Phoenix, la CLI de Rust, el SDK web y la infraestructura de despliegue. Eso hace que los mecanismos del trabajo lingüístico sean inspeccionables en cambio de una caja negra.

Glossia sigue un modelo open-core. El núcleo utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), lo que permite el uso comercial, el auto-alojamiento y los servicios hospedados competidores. El directorio `ee/` tiene una [Licencia empresarial](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada que requiere un acuerdo comercial escrito para el uso en producción. Consulte la licencia aplicable antes de redistribuir u operar funciones empresariales.
