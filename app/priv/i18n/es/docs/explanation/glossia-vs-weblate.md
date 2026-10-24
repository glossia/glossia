%{
  title: "Glossia frente a Weblate",
  summary:
    "Elige Glossia para trabajos lingüísticos dirigidos por modelos que sigan la entrega del repositorio y reutilicen tu validación existente.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Elige Glossia cuando quieras que la automatización lingüística funcione como el resto de la entrega de tu software:** instrucciones controladas por el repositorio, tus propios tokens de modelo, comprobaciones nativas del repositorio y pull requests para revisión.

[Weblate](https://weblate.org/) es un sistema de localización de código abierto con una interfaz de traducción web, integración con control de versiones y opciones de autoalojamiento. El código público y la integración con Git no son exclusivos de Glossia. La razón para elegir Glossia es su combinación de entrega centrada en el repositorio, transformaciones impulsadas por el modelo y contexto lingüístico reutilizable tanto para humanos como para agentes.

## ¿Por qué elegir Glossia

| Tu prioridad | Ventaja de Glossia |
|---|---|
| Mantener la revisión en el flujo de trabajo del producto | Revisa el resultado controlado por el repositorio real a través de los cambios en el repositorio y las pull requests. |
| Coincidir con un repositorio fuente de rápido movimiento | La detección de cambios y la publicación por lotes apoyan un ciclo de localización continuo sin traducir repetidamente las entradas sin cambios. |
| Trae tus propios tokens de modelo | Configura los modelos admitidos con credenciales de proveedor con ámbito de cuenta y selecciónalos con identificadores de propiedad del repositorio. |
| Reutilizar validación nativa | Ejecuta el comando de validación propio del repositorio en contra de un candidato en su ruta de destino real. |
| Reutilizar el contexto más allá de la traducción | La voz y terminología compartidas pueden orientar el nuevo contenido y las integraciones de agentes a través de las interfaces MCP y REST. |

## Mantener el repositorio como la superficie de revisión

Glossia está diseñado para un equipo que ya usa Git para decidir qué está listo para lanzar. Su configuración de localización vive junto al contenido, y sus salidas propuestas pueden ser revisadas a través del mismo proceso que el cambio del producto.

Weblate también se integra con el control de versiones. Su interfaz de traducción basada en el navegador puede ser exactamente lo que necesita una comunidad de contribuyentes. El énfasis de Glossia es diferente: preservar el límite de revisión del repositorio y llevar la automatización lingüística a él, en lugar de hacer que otra interfaz de edición sea el centro del trabajo del equipo.

## Trae tus propios tokens y haz que las elecciones de modelos sean explícitas

Glossia utiliza modelos admitidos configurados con tus tokens de API de proveedor. La configuración del repositorio se refiere a los manejadores estables de modelos; los secretos se mantienen en la configuración de cuenta. Puedes seleccionar diferentes modelos configurados por el ámbito del contenido o el destino de localización y rotar las credenciales sin cambiar cada repositorio.

Esto da a tu equipo un lugar explícito para elegir los modelos que generan su contenido. No promete que ningún token o modelo esté admitido, ni que la generación elimine la necesidad de revisión humana. Consulta [Configuración de un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilizar las comprobaciones que definen un cambio entregable

Las comprobaciones estructurales embebidas de Glossia son solo parte del límite de calidad. A través de `L10N.md` puede ejecutar un script de validación nativo del repositorio, un parser, un compilador o una comprobación de documentación sobre el candidato en su ruta de destino real.

Esto es útil cuando el contenido traducido incluye más que cadenas simples: formatos específicos de aplicación, componentes de Markdown, metadatos estructurados y restricciones que el proyecto ya sabe cómo verificar. La validación y la recuperación permanecen conectadas a los archivos reales que tu pipeline publicará.

El entorno de ejecución todavía necesita las dependencias del validador, y la validación estructural no establece precisión lingüística. Consulta [L10N.md](/docs/reference/l10n-md) y [Recuperación de traducción](./translation-recovery).

## El código público es una línea base, no toda la comparación

El núcleo de Glossia utiliza [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), que permite el uso comercial, la modificación, la distribución, el autoalojamiento y los servicios alojados competidores conforme a sus términos. El código de `ee/` tiene una [licencia Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) independiente y requiere un acuerdo comercial por escrito para su uso en producción. Este modelo de núcleo abierto difiere de las licencias basadas en GPL de Weblate.

Si la licencia de código abierto ilimitada y una interfaz de traducción web establecida son tus criterios principales, Weblate merece consideración. Si el objetivo es **tus propias credenciales de modelo, las comprobaciones existentes del repositorio y el trabajo lingüístico que sigue la entrega de software**, Glossia reúne esas opciones en un sistema operativo de lenguaje.

Esta comparación no afirma que Weblate carezca de automatización, características de validación o integraciones de proveedor, y no promete migración automática o paridad de funcionalidades. Consulta [documentación de Weblate](https://docs.weblate.org/) para las capacidades actuales.
