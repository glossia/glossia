%{
  title: "Glossia frente a Crowdin",
  summary:
    "Elige Glossia para mantener la localización en Git, traer tus propios tokens del modelo y validar con las comprobaciones de tu repositorio.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Elija Glossia cuando la localización necesite avanzar a la velocidad de su entrega de software.** Su repositorio ya define cómo se revisan, validan y envían los cambios. Glossia lleva el trabajo de idiomas dentro de ese ciclo en lugar de establecer un espacio de trabajo de traducción separado como el centro de su proceso.

[Crowdin](https://crowdin.com/) ofrece gestión colaborativa de traducción, procesos de revisión, memorias de traducción e integraciones de repositorio. La ventaja de Glossia para un equipo de software es la combinación de contenido propiedad del repositorio, código fuente inspectable, sus propias credenciales de modelo y validación que comprende el proyecto real.

## ¿Por qué elegir Glossia

| Su prioridad | La ventaja de Glossia |
|---|---|
| Lanzar continuamente | Las ejecuciones de traducción siguen los cambios del código fuente y devuelven actualizaciones de repositorio revisables. El contenido no necesita un proceso de lanzamiento independiente. |
| Mantener el control de la implementación | La aplicación pública, la CLI y el código de implementación pueden inspeccionarse, modificarse y alojarse en servidores propios bajo los términos de la licencia. |
| Lleve sus propios tokens | Configure modelos compatibles con sus propios tokens de API de proveedores. Los archivos del repositorio se refieren a manejadores de modelos estables, no a secretos. |
| Reutilice las verificaciones que confía | Ejecute un comando de validación del repositorio contra el candidato en su ruta de destino real antes de aceptarlo. |
| Mantenga el contenido bajo su propiedad | Los archivos fuente, las salidas traducidas, la configuración y el historial de solicitudes de extracción permanecen en su repositorio. |

## Localización que se mantiene con los commits

Glossia funciona desde instrucciones `L10N.md` versionadas y detecta qué contenido necesita actualizarse. Las entradas sin cambios no necesitan ser traducidas de nuevo. Un proyecto mantiene una sola solicitud de extracción de traducción abierta y publica el progreso en lotes, reduciendo solicitudes de extracción innecesarias y ejecuciones repetidas de CI a medida que evoluciona el código fuente.

El resultado es un flujo de trabajo de idiomas diseñado alrededor de los mismos cambios pequeños y revisables que su equipo ya envía. Continuo no significa sin revisión: los revisores aún deciden qué es seguro fusionar.

Crowdin también admite integraciones de Git y automatización. La razón para elegir Glossia no es que Crowdin no pueda conectarse a un repositorio; es que la entrega del repositorio es la base del flujo de trabajo de Glossia, no solo un límite de integración.

## Sus tokens, sus opciones de modelo

No debería tener que volver a configurar la configuración del repositorio para rotar un token de proveedor o cambiar el modelo detrás de un flujo de trabajo de traducción. Glossia almacena credenciales en la configuración de la cuenta y expone manejadores estables al repositorio. Diferentes áreas de contenido o ubicaciones de destino pueden seleccionar modelos configurados diferentes.

Esto le da a su equipo control sobre las relaciones de proveedor compatibles y las opciones de modelo que utiliza. Vea [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Validar la salida como parte de su producto

Una traducción puede leerse bien y aún así romper una compilación de documentación, un componente, un marcador de posición o un analizador de aplicaciones. Glossia le permite reutilizar una verificación del repositorio en lugar de detenerse en la evaluación del editor del texto.

Si su repositorio ya proporciona un script de validación de documentación, refiérase a él directamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

El validador recibe al candidato en su ruta de destino real, devuelve un estado no nulo en caso de error y se ejecuta dentro del presupuesto de reintento configurado. Sus dependencias deben estar disponibles en el entorno de validación. Consulte [L10N.md](/docs/reference/l10n-md) para el contrato.

## Fuente pública, sin entregar el repositorio

Puede inspeccionar cómo funcionan las planificaciones de Glossia, cómo maneja las credenciales, cómo conserva el Markdown y cómo valida un resultado. Los archivos traducidos existentes pueden publicarse mediante la cadena de procesos de su repositorio incluso si el servicio de idiomas no está disponible.

Glossia está disponible como fuente bajo el [O'Saasy licencia](https://github.com/glossia/glossia/blob/main/LICENSE.md), que autoriza el autoalojamiento pero restringe los servicios alojados de competencia. No es una licencia de código abierto sin restricciones.

Crowdin aún puede ser apropiado para un programa centrado en la coordinación de contribuyentes y un editor de traducción dedicado. Para un equipo de software cuya prioridad es **contenido propiedad de Git, validación existente y localización que sigue la entrega**, Glossia está diseñado para ese trabajo.

Esta comparación no afirma que Crowdin carezca de automatización o cualquier forma de integración del proveedor, ni que Glossia migre automáticamente sus memorias e historial. Consulte [la documentación de Crowdin](https://support.crowdin.com/) para las capacidades actuales.
