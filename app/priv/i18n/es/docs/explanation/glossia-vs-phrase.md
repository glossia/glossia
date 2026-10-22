%{
  title: "Glossia vs Phrase",
  summary:
    "Elige un flujo de trabajo nativo del repositorio con fuente pública, tus propios tokens del modelo y verificaciones de entrega reutilizables.",
  category: "explicación",
  section: "translation",
  order: 22
}
---

**Elige Glossia cuando quieras que el trabajo lingüístico siga el sistema de entrega de tu producto, en lugar de crear un proceso paralelo de gestión de traducciones alrededor de él.** Mantén el contenido en Git, elige modelos admitidos usando tus propias credenciales y valida los resultados con las comprobaciones a las que tu repositorio ya confía.

[Phrase](https://phrase.com/) ofrece una Suite de localización, incluido Phrase Strings y Phrase TMS para diferentes necesidades de localización de software y traducción gestionada. Glossia adopta un enfoque centrado: ofrece a los equipos de software un sistema operativo de idioma que se ajusta a su ciclo existente de revisión y entrega.

## ## ¿Por qué elegir Glossia

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Entrega cambios de idioma con software | Los cambios del repositorio impulsan la localización y las salidas regresan como cambios revisables. |
| Inspecciona y controla el procesamiento | El código fuente público expone la aplicación e implementación de despliegue, con modificación y autoalojamiento permitidos según los términos de la licencia. |
| Trae tus propios tokens | Configura tus propias credenciales de proveedor de modelos admitidos; selecciona modelos a través de manejadores de cuenta en la configuración del repositorio. |
| Reutiliza los pipelines de validación | Ejecuta comprobaciones nativas del repositorio en candidatos de traducción en lugar de tratar la aprobación lingüística como prueba de que un archivo se compilará. |
| Conserva una propiedad duradera | Los archivos publicados, la configuración y el historial de solicitudes de extracción permanecen con el repositorio. |

## ## Incoporap la localización en la entrega continua

La detección de cambios de Glossia evita repetir el trabajo de traducción para entradas sin cambios. Su flujo de trabajo del repositorio mantiene una solicitud de extracción de traducción abierta por proyecto y publica el progreso por lotes, de modo que un repositorio fuente de cambios frecuentes no necesita un nuevo proceso de traducción para cada cambio pequeño.

El objetivo no es una carrera a la producción sin revisión. Es hacer que el trabajo lingüístico sea continuamente revisable y entregable a través del pipeline que tu equipo ya utiliza.

Phrase también ofrece APIs, integraciones y automatización. La ventaja que enfatiza Glossia es la alineación arquitectónica: el repositorio permanece como la autoridad de contenido y el límite de entrega, en lugar de ser solo un lugar para sincronizar los resultados de otro espacio de trabajo.

## Mantén la elección de modelo y las credenciales bajo tu control

Glossia acepta tus propios tokens de API de proveedor para modelos admitidos. Las credenciales permanecen en la configuración de la cuenta; los repositorios seleccionan manejadores estables. Un equipo puede rotar un token o cambiar el modelo detrás de un manejador sin reescribir sus instrucciones del repositorio.

Diferentes ámbitos de contenido y lenguajes objetivo pueden usar modelos configurados diferentes. Los modelos de decisión opcionales pueden evaluar traducciones completas y solicitar correcciones, mientras que los humanos permanecen responsables del juicio lingüístico. Consulta los [Modelos de cuenta](./account-models) para el comportamiento y los límites actuales.

## ## Tu repositorio ya sabe lo que significa el contenido válido

La visión de un sistema de gestión de traducción sobre una cadena no es necesariamente la visión de la aplicación sobre un archivo. Un repositorio puede tener su propio analizador, compilador, reglas de componente, construcción de documentación y comprobaciones de marcador de posición.

Glossia puede reutilizar esas comprobaciones mediante `L10N.md` comandos de validación. Escribe temporalmente al candidato a su ruta de destino real para validación y lo acepta solo después de que se cumplan las comprobaciones requeridas. El comando y sus dependencias deben estar disponibles en el entorno de ejecución.

Esto permite al equipo extender su límite de calidad existente en lugar de mantener una definición separada de "válido" exclusivamente dentro de un espacio de trabajo de traducción. Consulta [L10N.md](/docs/reference/l10n-md).

## ## Implementación pública, no una caja negra

La aplicación de Glossia, CLI, SDK y fuentes de despliegue son públicas. Puedes inspeccionar cómo se maneja el contenido y modificar o autoalojar la implementación bajo el [licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licencia limita los servicios alojados competidores y no es una licencia de código abierto sin restricciones.

Un conjunto de traducción más amplio puede tener sentido para operaciones de traducción especializadas y coordinación compleja. Si tu prioridad es **hacer coincidir la velocidad de entrega de software con tus propios tokens y comprobaciones del repositorio**, Glossia está diseñado para mantener ese flujo de trabajo directo.

Mover un programa de traducción establecido aún requiere un plan para sus memorias, terminología e historial. Esta página no promete un importador automático de Phrase o una paridad completa del conjunto, ni afirma que Phrase carezca de todas las integraciones equivalentes. Consulta la [documentación de Phrase](https://support.phrase.com/) para las capacidades actuales del producto específico.
