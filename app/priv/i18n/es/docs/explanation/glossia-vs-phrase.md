%{
  title: "Glossia frente a Phrase",
  summary:
    "Elige un flujo de trabajo de idioma nativo del repositorio con código fuente público, tus propios tokens de modelo y comprobaciones de entrega reutilizables.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Elige Glossia cuando quieras que el trabajo de idiomas siga el sistema de entrega de tu producto, en lugar de construir un proceso paralelo de gestión de traducción alrededor de él.** Mantén el contenido en Git, selecciona modelos soportados usando tus propias credenciales y valida los resultados con las comprobaciones que tu repositorio ya confía.

[Phrase](https://phrase.com/) proporciona un conjunto de herramientas de localización, incluyendo Phrase Strings y Phrase TMS para diferentes necesidades de localización de software y traducción gestionada. Glossia adopta un enfoque enfocado: proporciona a los equipos de software un sistema operativo de idiomas que encaja con su ciclo actual de revisión y entrega.

## ¿Por qué elegir Glossia

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Entrega cambios de idioma junto con el software | Los cambios del repositorio impulsan la localización, y las salidas devuelven como cambios revisables. |
| Inspecciona y controla el procesamiento | El código fuente público expone la implementación de la aplicación y el despliegue, permitiendo modificaciones y autoalojamiento bajo los términos de la licencia. |
| Trae tus propios tokens | Configura tus propias credenciales de proveedor de modelos soportados; selecciona modelos a través de manejadores de cuenta en la configuración del repositorio. |
| Reutiliza los pipelines de validación | Ejecuta comprobaciones nativas del repositorio sobre candidatos de traducción en lugar de tratar la aprobación lingüística como prueba de que un archivo se compilará. |
| Mantén una propiedad duradera | Los archivos publicados, la configuración y el historial de solicitudes de extracción se mantienen con el repositorio. |

## Incluye localización en la entrega continua

La detección de cambios de Glossia evita repetir el trabajo de traducción para entradas inalteradas. Su flujo de trabajo del repositorio mantiene una sola solicitud de extracción de traducción abierta por proyecto y publica el progreso en lotes, por lo que un repositorio de origen en rápida evolución no necesita un nuevo proceso de traducción para cada cambio pequeño.

El objetivo no es una carrera no revisada hacia la producción. Es hacer que el trabajo de idiomas sea continuamente revisable y entregable a través del pipeline que ya utiliza tu equipo.

Phrase ofrece APIs, integraciones y automatización también. La ventaja que enfatiza Glossia es la alineación arquitectónica: el repositorio permanece como la autoridad del contenido y el límite de entrega, en lugar de ser solo un lugar para sincronizar los resultados de otro espacio de trabajo.

## Mantén la elección de modelos y credenciales bajo tu control

Glossia acepta tus propios tokens de API del proveedor para modelos soportados. Las credenciales se mantienen en la configuración de cuenta; los repositorios seleccionan manejadores estables. Un equipo puede rotar un token o cambiar el modelo detrás de un manejador sin reescribir sus instrucciones del repositorio.

Los diferentes ámbitos de contenido y los idiomas objetivo pueden utilizar modelos configurados diferentes. Los modelos de decisión opcionales pueden evaluar traducciones completas y solicitar correcciones, mientras que las personas siguen siendo responsables del juicio lingüístico. Consulta [Modelos de cuenta](./account-models) para el comportamiento y los límites actuales.

## Tu repositorio ya sabe qué significa el contenido válido

La visión de un sistema de gestión de traducción de una cadena no es necesariamente la visión de la aplicación de un archivo. Un repositorio puede tener su propio analizador, compilador, reglas de componentes, compilación de documentación y comprobaciones de marcadores.

Glossia puede reutilizar esas comprobaciones a través `L10N.md` de comandos de validación. Lo escribe temporalmente en su ruta de destino real para validación y lo acepta solo después de que pasen las comprobaciones requeridas. El comando y sus dependencias deben estar disponibles en el entorno de ejecución.

Esto permite al equipo extender su límite de calidad existente en lugar de mantener una definición separada de "válido" exclusivamente dentro de un espacio de trabajo de traducción. Consulta [L10N.md](/docs/reference/l10n-md).

## Implementación pública, no una caja negra

La aplicación de Glossia, la CLI, el SDK y las fuentes de implementación son públicos. Puedes inspeccionar cómo se maneja el contenido y modificar o autoalojar la implementación bajo la [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licencia restringe los servicios alojados competidores y no es una licencia de código abierto sin restricciones.

Un conjunto de herramientas de traducción más amplio puede tener sentido para operaciones de traducción especializadas y coordinación compleja. Si tu prioridad es **alinear la velocidad de entrega de software con tus propios tokens y comprobaciones del repositorio**, Glossia está diseñado para mantener ese flujo de trabajo directo.

Mover un programa de traducción establecido aún requiere un plan para sus memorias, terminología e historia. Esta página no promete un importador automático de Phrase ni una equivalencia completa de la suite, ni afirma que Phrase carece de todas las integraciones equivalentes. Consulta [la documentación de Phrase](https://support.phrase.com/) para las capacidades actuales del producto específico.
