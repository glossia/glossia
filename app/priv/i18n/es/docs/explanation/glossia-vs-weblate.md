%{
  title: "Glossia frente a Weblate",
  summary:
    "Elige Glossia para trabajo de lenguaje basado en modelos que sigue la entrega del repositorio y reutiliza tu validación existente.",
  category: "explicación",
  section: "translation",
  order: 23
}
---

**Elija Glossia cuando quiera que la automatización de idioma funcione como el resto de su entrega de software:** instrucciones controladas por código fuente, sus propios tokens del modelo, verificaciones nativas del repositorio, y solicitudes de extracción para revisión.

[Weblate](https://weblate.org/) es un sistema de localización de código abierto con una interfaz de traducción web, integración de control de versiones, y opciones de autoalojamiento. El código público y la integración de Git no son exclusivos de Glossia. La razón para elegir Glossia es su combinación de entrega centrada en el repositorio, transformaciones impulsadas por modelos, y contexto de idioma reutilizable tanto para humanos como para agentes.

## ¿Por qué elegir Glossia

| Su prioridad | Ventaja de Glossia |
|---|---|
| Mantener la revisión en el flujo de trabajo del producto | Revise la salida real controlada por código fuente a través de cambios del repositorio y solicitudes de extracción. |
| Ajustarse a un repositorio fuente de rápida evolución | La detección de cambios y la publicación por lotes apoyan un bucle de localización continuo sin traducir repetidamente los insumos sin cambios. |
| Traiga sus propios tokens del modelo | Configure modelos soportados con credenciales de proveedor de alcance de cuenta y selecciónelos con manejadores propiedad del repositorio. |
| Reutilice la validación nativa | Ejecute la propia orden de validación del repositorio contra un candidato en su ruta de destino real. |
| Reutilice el contexto más allá de la traducción | La voz y terminología compartidas pueden guiar el nuevo contenido e integraciones de agente a través de interfaces MCP y REST. |

## Mantenga el repositorio como la superficie de revisión

Glossia está diseñado para un equipo que ya usa Git para decidir qué está listo para enviar. Su configuración de localización vive junto al contenido, y sus salidas propuestas pueden ser revisadas a través del mismo proceso que el cambio del producto.

Weblate también se integra con control de versiones. Su interfaz de traducción basada en el navegador puede ser exactamente lo que una comunidad de colaboradores necesita. El énfasis de Glossia es diferente: preserve el límite de revisión del repositorio y traiga automatización de idioma a él, en lugar de hacer otra interfaz de edición el centro del trabajo del equipo.

## Traiga sus propios tokens y haga las elecciones del modelo explícitas

Glossia usa modelos soportados configurados con sus tokens de API de proveedor. La configuración del repositorio se refiere a manejadores de modelo estables; los secretos permanecen en la configuración de cuenta. Puede seleccionar diferentes modelos configurados por alcance de contenido o tipo de destino y rotar credenciales sin cambiar cada repositorio.

Eso le da a su equipo un lugar explícito para elegir los modelos que escriben su contenido. No promete que ningún token o modelo está soportado, ni que la generación elimina la necesidad de revisión humana. Vea [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Reutilice las verificaciones que definen un cambio entregable

Las comprobaciones estructurales integradas de Glossia son solo parte del límite de calidad. Mediante `L10N.md`, puede ejecutar un script nativo de validación del repositorio, un analizador, un compilador o una comprobación de documentación sobre el candidato en su ruta de destino real.

Esto es útil cuando el contenido traducido incluye más que cadenas simples: formatos específicos para aplicaciones, componentes de Markdown, metadatos estructurados, y restricciones que el proyecto ya sabe cómo verificar. La validación y recuperación permanecen conectadas a los archivos reales que su canal publicará.

El entorno de ejecución aún necesita las dependencias del validador, y la validación estructural no establece precisión lingüística. Vea [L10N.md](/docs/reference/l10n-md) y [Recuperación de traducción](./translation-recovery).

## El código fuente público es una línea base, no la comparación completa

La implementación de Glossia es pública y puede ser inspeccionada, modificada, y autoalojada bajo [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licencia restringe servicios alojados competidores; no es lo mismo que la licencia de código abierto basada en GPL de Weblate.

Si la licencias abierta sin restricciones y una interfaz web de traducción establecida son sus criterios principales, Weblate merece consideración. Si el objetivo es **sus propias credenciales de modelo, verificaciones existentes del repositorio, y trabajo de idioma que sigue la entrega de software**, Glossia reúne esas elecciones en un sistema operativo de idioma.

Esta comparación no afirma que Weblate carezca de automatización, características de validación, o integraciones de proveedor, y no promete migración automática o paridad en características. Vea [Documentación de Weblate](https://docs.weblate.org/) para capacidades actuales.
