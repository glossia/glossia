%{
  title: "Glossia frente a Phrase",
  summary:
    "Elige un flujo de trabajo lingüístico nativo del repositorio con fuente pública, sus propios tokens de modelo y validaciones de entrega reutilizables.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Elige Glossia cuando quieras que el trabajo de lenguaje siga el sistema de entrega de tu producto, en lugar de construir un proceso de gestión de traducciones paralelo alrededor de él.** Mantén el contenido en Git, elige modelos compatibles usando tus propias credenciales y valida los resultados con las comprobaciones en las que tu repositorio ya confía.

[Phrase](https://phrase.com/) proporciona un paquete de localización, incluido Phrase Strings y Phrase TMS para diferentes necesidades de localización de software y gestión de traducciones. Glossia toma un enfoque enfocado: ofrece a los equipos de software un sistema operativo de lenguaje que se ajuste a su ciclo existente de revisión y entrega.

## ¿Por qué elegir Glossia?

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Entrega de cambios de lenguaje con el software | Los cambios del repositorio impulsan la localización, y los resultados devuelven cambios revisables. |
| Inspecciona y controla el procesamiento | El código fuente público expone la aplicación y la implementación de despliegue, permitiendo la modificación y el autoalojamiento bajo los términos de la licencia. |
| Trae tus propios tokens | Configura tus propias credenciales del proveedor de modelos compatibles; selecciona modelos a través de identificadores de cuenta en la configuración del repositorio. |
| Reutiliza los flujos de validación | Ejecuta comprobaciones nativas del repositorio en los candidatos de traducción, en lugar de tratar la aprobación lingüística como prueba de que un archivo compilará. |
| Mantén la propiedad duradera | Los archivos publicados, la configuración y el historial de solicitudes de extracción permanecen en el repositorio. |

## Convierte la localización en parte de la entrega continua

La detección de cambios de Glossia evita repetir el trabajo de traducción para entradas sin cambios. Su flujo de trabajo de repositorio mantiene una solicitud de extracción de traducción abierta por proyecto y publica el progreso en lotes, por lo que un repositorio de origen de rápida evolución no necesita un nuevo proceso de traducción para cada pequeño cambio.

El objetivo no es una carrera sin revisión hacia la producción. Se trata de hacer que el trabajo de lenguaje sea continuamente revisable y entregable a través del pipeline que tu equipo ya utiliza.

Phrase ofrece APIs, integraciones y automatización también. La ventaja que Glossia enfatiza es la alineación arquitectónica: el repositorio permanece como la autoridad de contenido y el límite de entrega, en lugar de ser solo un lugar para sincronizar los resultados de otro espacio de trabajo.

## Mantén la elección de modelos y las credenciales bajo tu control

Glossia acepta tus propios tokens de API del proveedor para modelos compatibles. Las credenciales permanecen en la configuración de la cuenta; los repositorios seleccionan identificadores estables. Un equipo puede rotar un token o cambiar el modelo detrás de un identificador sin reescribir sus instrucciones del repositorio.

Los diferentes ámbitos de contenido y los idiomas de destino pueden utilizar modelos configurados diferentes. Los modelos de decisión opcionales pueden evaluar traducciones completas y solicitar correcciones, mientras los humanos permanecen responsables del juicio lingüístico. Consulta [Modelos de cuenta](./account-models) para el comportamiento y límites actuales.

## Tu repositorio ya sabe qué significa el contenido válido

La visión de un sistema de gestión de traducciones sobre una cadena no es necesariamente la visión de una aplicación sobre un archivo. Un repositorio puede tener su propio parser, compilador, reglas de componente, construcción de documentación y comprobaciones de placeholders.

Glossia puede reutilizar esas comprobaciones a través `L10N.md` de comandos de validación. Escrebe el candidato temporalmente a su ruta real de destino para la validación y lo acepta solo después de pasar las comprobaciones necesarias. El comando y sus dependencias deben estar disponibles en el entorno de ejecución.

Esto permite al equipo extender su límite de calidad existente en lugar de mantener una definición separada de "válido" únicamente dentro de un espacio de trabajo de traducción. Consulta [L10N.md](/docs/reference/l10n-md).

## Implementación pública, no una caja negra

La aplicación, CLI, SDK y fuentes de despliegue de Glossia son públicas. El núcleo es de código abierto bajo [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), lo que permite la modificación, distribución, autoalojamiento y servicios de alojamiento competidores. El código empresarial bajo `ee/` tiene una [licencia](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada que requiere un acuerdo comercial escrito para uso en producción.

Una suite de traducción más amplia puede tener sentido para operaciones especializadas de traducción y coordinación compleja. Si tu prioridad es **hacer coincidir la velocidad de entrega de software con tus propios tokens y las comprobaciones del repositorio**, Glossia está diseñado para mantener ese flujo directo.

Trasladar un programa de traducción consolidado aún requiere un plan para sus memorias, terminología e historia. Esta página no promete un importador automático de Phrase ni la paridad de la suite completa, ni afirma que Phrase carezca de todas las integraciones equivalentes. Consulta [Documentación de Phrase](https://support.phrase.com/) para las capacidades actuales del producto específico.
