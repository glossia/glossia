%{
  title: "Glossia frente a Phrase",
  summary:
    "Elija un flujo de trabajo lingüístico nativo del repositorio con código fuente público, sus propios tokens de modelo y comprobaciones de entrega reutilizables.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 22
}
---

**Elija Glossia cuando desea que el trabajo del idioma siga el sistema de entrega de su producto, en lugar de construir un proceso paralelo de gestión de traducciones en torno a él.** Mantenga el contenido en Git, elija modelos compatibles usando sus propias credenciales y valide los resultados con las comprobaciones que su repositorio ya confía.

[Phrase](https://phrase.com/) proporciona una suite de localización, incluyendo Phrase Strings y Phrase TMS para distintas necesidades de localización de software y traducción gestionada. Glossia adopta un enfoque enfocado: proporcione a los equipos de software un OS de idiomas que se ajuste a su ciclo de revisión y entrega existente.

## ¿Por qué elegir Glossia

| Su prioridad | La ventaja de Glossia |
|---|---|
| Entregar cambios de idioma junto con el software | Los cambios del repositorio impulsan la localización, y los resultados devuelven cambios revisables. |
| Inspeccionar y controlar el procesamiento | El código fuente público expone la aplicación y la implementación de despliegue, permitiendo la modificación y autogestión bajo los términos de la licencia. |
| Use sus propios tokens | Configure sus propias credenciales del proveedor compatibles con el modelo; seleccione modelos a través de identificadores de cuenta en la configuración del repositorio. |
| Reutilice los pipelines de validación | Ejecute comprobaciones nativas del repositorio sobre los candidatos de traducción en lugar de tratar la aprobación lingüística como prueba de que un archivo se compilará. |
| Mantenga una propiedad duradera | Los archivos publicados, la configuración y el historial de requests del pull permanecen en el repositorio. |

## Integre la localización como parte de la entrega continua

La detección de cambios de Glossia evita repetir el trabajo de traducción para las entradas sin cambios. Su flujo de trabajo del repositorio mantiene una solicitud de traducción abierta por proyecto y publica el progreso en lotes, por lo que un repositorio fuente de rápido movimiento no necesita un nuevo proceso de traducción para cada cambio pequeño.

El objetivo no es una carrera hacia la producción sin revisión. El punto es hacer que el trabajo del idioma sea continuamente revisable y entregable a través del pipeline que su equipo ya usa.

Phrase también ofrece APIs, integraciones y automatización. La ventaja que Glossia enfatiza es el alineamiento arquitectónico: el repositorio permanece como la autoridad del contenido y el límite de entrega, en lugar de ser solo un lugar para sincronizar los resultados de otro espacio de trabajo.

## Mantenga la elección del modelo y las credenciales bajo su control

Glossia acepta sus propios tokens de API del proveedor para modelos compatibles. Las credenciales permanecen en la configuración de la cuenta; los repositorios seleccionan identificadores estables. Un equipo puede rotar un token o cambiar el modelo detrás de un identificador sin reescribir sus instrucciones del repositorio.

Diferentes ámbitos de contenido y lenguajes objetivo pueden usar modelos configurados distintos. Los modelos de decisión opcionales pueden evaluar traducciones completas y solicitar correcciones, mientras las personas continúan siendo responsables del juicio lingüístico. Consulte [Modelos de cuenta](./account-models) para el comportamiento y los límites actuales.

## Su repositorio ya sabe qué significa el contenido válido

La visión de un sistema de gestión de traducciones sobre una cadena no es necesariamente la visión de la aplicación sobre un archivo. Un repositorio puede tener su propio analizador, compilador, reglas de componentes, construcción de documentación y verificación de placeholders.

Glossia puede reutilizar esas comprobaciones a través de los comandos de validación `L10N.md`. Escriba temporalmente el candidato a su ruta de destino real para su validación y solo lo acepte después de que pasen las comprobaciones requeridas. El comando y sus dependencias deben estar disponibles en el entorno de ejecución.

Esto permite al equipo ampliar su límite de calidad existente en lugar de mantener una definición separada de "válido" exclusivamente dentro de un espacio de traducción. Consulte [L10N.md](/docs/reference/l10n-md).

## Implementación pública, no una caja negra

La aplicación de Glossia, la CLI, el SDK y las fuentes de despliegue son públicas. Puede inspeccionar cómo se maneja el contenido y modificar o auto-alojar la implementación bajo la [O'Saasy licencia](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licencia restringe servicios alojados competidores y no es una licencia de código abierto sin restricciones.

Una suite de traducción más amplia puede tener sentido para operaciones especializadas de traducción y coordinación compleja. Si su prioridad es **igualar la velocidad de entrega del software con sus propios tokens y comprobaciones del repositorio**, Glossia está diseñado para mantener ese flujo de trabajo directo.

Mover un programa de traducción establecido aún requiere un plan para sus memorias, terminología e historial. Esta página no promete un importador de Phrase automático ni una paridad completa de la suite, ni afirma que Phrase carezca de todas las integraciones equivalentes. Consulte [Documentación de Phrase](https://support.phrase.com/) para las capacidades actuales del producto específico.
