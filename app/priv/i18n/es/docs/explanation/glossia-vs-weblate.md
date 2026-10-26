%{
  title: "Glossia frente a Weblate",
  summary:
    "Elige Glossia para trabajo lingüístico dirigido por modelos que respeta la entrega de repositorio y reutiliza tu validación existente.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Elija Glossia cuando quiera que la automatización de idioma funcione como el resto de su entrega de software:** instrucciones controladas por código fuente, tus propios tokens del modelo, comprobaciones nativas del repositorio y pull requests para revisión.

[Weblate](https://weblate.org/) es un sistema de localización de código abierto con una interfaz de traducción web, integración con control de versiones y opciones de auto-alojamiento. El código público y la integración con Git no son exclusivos de Glossia. La razón para elegir Glossia es su combinación de entrega centrada en el repositorio, transformaciones impulsadas por modelos y contexto de idioma reutilizable tanto para humanos como para agentes.

## ¿Por qué elegir Glossia

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Mantener la revisión en el flujo de producto | Revisa la salida real controlada por código fuente a través de cambios en el repositorio y pull requests. |
| Adaptarse a un repositorio de origen en movimiento rápido | La detección de cambios y la publicación en lotes apoyan un bucle de localización continuo sin traducir repetidamente entradas sin cambios. |
| Lleva tus propios tokens del modelo | Configura modelos compatibles con credenciales del proveedor con ámbito de cuenta y selecciónéalos con manejadores de propiedad del repositorio. |
| Reutilizar validación nativa | Ejecuta el propio comando de validación del repositorio contra un candidato en su ruta real de destino. |
| Reutilizar contexto más allá de la traducción | La voz y terminología compartidas pueden guiar el nuevo contenido y las integraciones de agentes a través de interfaces MCP y REST. |

## Mantener el repositorio como la superficie de revisión

Glossia está diseñado para un equipo que ya usa Git para decidir qué está listo para lanzar. Su configuración de localización vive junto al contenido, y sus salidas propuestas pueden revisarse a través del mismo proceso que el cambio del producto.

Weblate también integra con control de versiones. Su interfaz de traducción basada en el navegador puede ser exactamente lo que necesita una comunidad de contribuyentes. El énfasis de Glossia es diferente: preserve el límite de revisión del repositorio y lleva la automatización de idioma a él, en lugar de hacer otra interfaz de edición el centro del trabajo del equipo.

## Lleva tus propios tokens y haz explícitas las elecciones de modelo

Glossia usa modelos compatibles configurados con los tokens de API de tu proveedor. La configuración del repositorio se refiere a manejadores de modelo estables; los secretos permanecen en la configuración de la cuenta. Puedes seleccionar diferentes modelos configurados por ámbito de contenido o destino de idioma y rotar credenciales sin cambiar cada repositorio.

Eso da a tu equipo un lugar explícito para elegir los modelos que escriben su contenido. No promete que ningún token o modelo sea compatible, ni que la generación elimina la necesidad de revisión humana. Vea [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider).

## Reutilizar las comprobaciones que definen un cambio entregable

Las comprobaciones estructurales integradas de Glossia son solo parte del límite de calidad. A través `L10N.md` de puede ejecutar el script de validación nativo del repositorio, analizador, compilador o verificación de documentación del candidato en su ruta real de destino.

Esto es útil cuando el contenido traducido incluye más que cadenas simples: formatos específicos de aplicación, componentes de Markdown, metadatos estructurados y restricciones que el proyecto ya sabe cómo verificar. La validación y recuperación permanecen conectadas a los archivos reales que tu pipeline publicará.

El entorno de ejecución aún necesita las dependencias del validador, y la validación estructural no establece precisión lingüística. Consulte [L10N.md](/docs/reference/l10n-md) y [Recuperación de traducción](./translation-recovery).

## El código fuente público es una línea base, no la comparación completa

El núcleo de Glossia es público y puede ser inspeccionado, modificado, distribuido y autohospedado bajo [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), lo que permite servicios alojados competidores. El código empresarial bajo `ee/` tiene una [licencia](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada que requiere un acuerdo comercial escrito para uso de producción. Este modelo de open core difiere de la licencia basada en GPL de Weblate.

Si la licencia basada en GPL y una interfaz de traducción web establecida son tus criterios principales, Weblate merece consideración. Si el objetivo es **tus propias credenciales de modelo, comprobaciones de repositorio existentes y trabajo de idioma que sigue la entrega de software**, Glossia reúne esas opciones en un sistema operativo de idioma.

Esta comparación no indica que Weblate carezca de automatización, características de validación o integraciones de proveedor, y no promete migración automática o equivalencia de funcionalidades. Consulte [documentación de Weblate](https://docs.weblate.org/) para las capacidades actuales.
