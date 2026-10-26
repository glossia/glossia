%{
  title: "Glossia frente a Weblate",
  summary:
    "Elige Glossia para trabajo de idioma impulsado por modelos que siga la entrega del repositorio y reutilice tu validación existente.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Elije Glossia cuando quieras que la automatización del idioma funcione como el resto de tu entrega de software:** instrucciones controladas por el código, tus propios tokens de modelo, comprobaciones nativas del repositorio y pull requests para revisión.

[Weblate](https://weblate.org/) es un sistema de localización de código abierto con una interfaz web de traducción, integración con control de versiones y opciones de auto-hospedarse. El código público y la integración con Git no son exclusivos de Glossia. La razón para elegir Glossia es su combinación de entrega centrada en el repositorio, transformaciones impulsadas por modelos y contexto de idioma reutilizable tanto para humanos como para agentes.

## ¿Por qué elegir Glossia

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Mantener la revisión en el flujo del producto | Revisa la salida real controlada por el código en el repositorio a través de los cambios del repositorio y pull requests. |
| Adaptarse a un repositorio fuente en movimiento rápido | La detección de cambios y la publicación por lotes permiten un ciclo continuo de localización sin traducir repetidamente las entradas sin cambios. |
| Trae tus propios tokens de modelo | Configura los modelos soportados con credenciales del proveedor con alcance de cuenta y selecciónalos con identificadores propiedad del repositorio. |
| Reutilizar la validación nativa | Ejecuta el propio comando de validación del repositorio contra un candidato en su camino de destino real. |
| Reutilizar el contexto más allá de la traducción | El tono compartido y la terminología pueden orientar el nuevo contenido y las integraciones de agentes a través de interfaces MCP y REST. |

## Mantener el repositorio como la superficie de revisión

Glossia está diseñado para un equipo que ya usa Git para decidir qué está listo para lanzar. Su configuración de localización vive junto al contenido, y sus propuestas de salida pueden ser revisadas a través del mismo proceso que el cambio del producto.

Weblate también integra con control de versiones. Su interfaz web de traducción basada en navegador puede ser exactamente lo que necesita una comunidad contribuyente. El énfasis de Glossia es diferente: preservar el límite de revisión del repositorio y traer automatización del idioma hacia él, en lugar de hacer otra interfaz de edición el centro del trabajo del equipo.

## Trae tus propios tokens y haz explícitas las elecciones de modelos

Glossia usa modelos soportados configurados con los tokens de API de tu proveedor. La configuración del repositorio se refiere a manejadores de modelos estables; los secretos permanecen en la configuración de cuenta. Puedes seleccionar diferentes modelos configurados por alcance de contenido o localización de destino y rotar credenciales sin cambiar cada repositorio.

Esto da a tu equipo un lugar explícito para elegir los modelos que escriben su contenido. No promete que cualquier token o modelo sea compatible, ni que la generación elimine la necesidad de revisión humana. Ver [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider).

## Reutilizar las comprobaciones que definen un cambio entregable

Las comprobaciones estructurales integradas en Glossia son solo parte del límite de calidad. A través `L10N.md` puede ejecutar un script, parser, compilador o comprobación de documentación nativo del repositorio sobre el candidato en su camino de destino real.

Esto es útil cuando el contenido traducido incluye más que cadenas simples: formatos específicos de aplicación, componentes Markdown, metadatos estructurados y limitaciones que el proyecto ya sabe cómo verificar. La validación y recuperación permanecen conectadas a los archivos reales que tu pipeline publicará.

El entorno de ejecución aún necesita las dependencias del validador, y la validación estructural no establece precisión lingüística. Ver [L10N.md](/docs/reference/l10n-md) y [Recuperación de traducción](./translation-recovery).

## El código fuente público es un punto de referencia, no la comparación completa

La implementación de Glossia es pública y puede ser inspeccionada, modificada y auto-hospedada bajo [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licencia limita servicios de alojamiento competidores; no es lo mismo que la licencia de código abierto basada en GPL de Weblate.

Si la licensing de código abierto sin restricciones y una interfaz web de traducción establecida son tus criterios principales, Weblate merece consideración. Si el objetivo es **tus propias credenciales de modelo, comprobaciones del repositorio existentes y trabajo de idioma que sigue la entrega de software**, Glossia reúne esas opciones en un sistema operativo de lenguaje.

Esta comparación no afirma que Weblate carece de automatización, características de validación o integraciones de proveedor, y no promete migración automática o paridad funcional. Ver [Documentación de Weblate](https://docs.weblate.org/) para capacidades actuales.
