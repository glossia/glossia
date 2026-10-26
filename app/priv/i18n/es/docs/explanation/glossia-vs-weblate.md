%{
  title: "Glossia frente a Weblate",
  summary:
    "Elija Glossia para el trabajo lingüístico impulsado por modelos que sigue la entrega del repositorio y reutiliza su validación existente.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Elige Glossia cuando quieras que la automatización del idioma funcione como el resto de tu entrega de software:** instrucciones controladas por el repositorio, tus propios tokens de modelo, comprobaciones nativas del repositorio y peticiones de extracción para revisión.

El [Weblate](https://weblate.org/) es un sistema de localización de código abierto con una interfaz web de traducción, integración con control de versiones y opciones de autoalojamiento. El código público y la integración con Git no son exclusivos de Glossia. La razón para elegir Glossia es su combinación de entrega centrada en el repositorio, transformaciones impulsadas por modelos y contexto de idioma reutilizable tanto para humanos como para agentes.

## ¿Por qué elegir Glossia

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Mantener la revisión en el flujo del producto | Revisa la salida real controlada por el repositorio a través de los cambios del repositorio y las peticiones de extracción. |
| Coincidir con un repositorio de origen en rápido movimiento | La detección de cambios y la publicación por lotes apoyan un ciclo de localización continuo sin traducir repetidamente las entradas inalteradas. |
| Trae tus propios tokens de modelo | Configura modelos compatibles con credenciales del proveedor con alcance de cuenta y selecciónalos con identificadores propiedad del repositorio. |
| Reaprovecha la validación nativa | Ejecuta el propio comando de validación del repositorio sobre un candidato en su ruta de destino real. |
| Reaprovecha el contexto más allá de la traducción | La voz compartida y la terminología pueden guiar el nuevo contenido y las integraciones de agentes a través de interfaces MCP y REST. |

## Mantener el repositorio como la superficie de revisión

Glossia está diseñado para un equipo que ya usa Git para decidir qué está listo para lanzar. Su configuración de localización vive junto al contenido, y sus salidas propuestas pueden ser revisadas a través del mismo proceso que el cambio del producto.

Weblate también se integra con el control de versiones. Su interfaz web de traducción basada en el navegador puede ser exactamente lo que necesita una comunidad de colaboradores. El énfasis de Glossia es diferente: conserva el límite de revisión del repositorio y lleva la automatización del idioma a él, en lugar de hacer otra interfaz de edición al centro del trabajo del equipo.

## Trae tus propios tokens y haz explícitas las elecciones de modelo

Glossia usa modelos compatibles configurados con tus tokens API del proveedor. La configuración del repositorio se refiere a los identificadores de modelos estables; los secretos permanecen en la configuración de la cuenta. Puedes seleccionar diferentes modelos configurados por el alcance del contenido o el idioma de destino y rotar las credenciales sin cambiar cada repositorio.

Esto le da a tu equipo un lugar explícito para elegir los modelos que escriben su contenido. No promete que ningún token o modelo sea compatible, ni que la generación elimine la necesidad de revisión humana. Ver [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutiliza los comprobantes que definen un cambio entregable

Los comprobantes estructurales integrados en Glossia son solo parte del límite de calidad. A través de `L10N.md`, puede ejecutar un script de validación nativo del repositorio, parser, compilador o comprobador de documentación sobre el candidato en su ruta de destino real.

Esto es útil cuando el contenido traducido incluye más que cadenas simples: formatos específicos de la aplicación, componentes Markdown, metadatos estructurados y restricciones que el proyecto ya sabe cómo verificar. La validación y la recuperación permanecen conectadas a los archivos reales que tu tubería publicará.

El entorno de ejecución aún necesita las dependencias del validador, y la validación estructural no establece la precisión lingüística. Ver [L10N.md](/docs/reference/l10n-md) y [Recuperación de traducción](./translation-recovery).

## La fuente pública es un punto de base, no toda la comparación

El núcleo de Glossia utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite el uso comercial, la modificación, la distribución, el autoalojamiento y los servicios alojados competidores conforme a sus términos. El código de `ee/` tiene una [licencia Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) independiente y requiere un acuerdo comercial por escrito para su uso en producción. Este modelo de núcleo abierto difiere de las licencias basadas en GPL de Weblate.

Si la licencia de código abierto sin restricciones y una interfaz web de traducción establecida son tus criterios principales, Weblate merece consideración. Si el objetivo es **tus propias credenciales de modelo, las comprobaciones existentes del repositorio y el trabajo de idioma que sigue la entrega de software**, Glossia reúne esas elecciones en un Sistema Operativo de Idiomas.

Esta comparación no afirma que Weblate falte automatización, características de validación o integraciones de proveedores, y no promete migración automática o paridad de funciones. Ver [Documentación de Weblate](https://docs.weblate.org/) para las capacidades actuales.
