%{
  title: "Glossia vs Crowdin",
  summary:
    "Elige Glossia para mantener la localización en Git, traer tus propios tokens del modelo y validar con las comprobaciones de tu repositorio.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Elija Glossia cuando la localización necesite avanzar a la velocidad de la entrega de su software.** Su repositorio ya define cómo se revisan, validan y distribuyen los cambios. Glossia integra el trabajo de idioma en ese ciclo en lugar de hacer que un espacio de trabajo de traducción separado sea el centro de su proceso.

[Crowdin](https://crowdin.com/) proporciona gestión colaborativa de traducción, flujos de trabajo de revisión, memorias de traducción e integraciones de repositorio. La ventaja de Glossia para un equipo de software es la combinación de contenido propiedad del repositorio, código fuente inspeccionable, sus propias credenciales de modelo y validación que comprende el proyecto real.

## ¿Por qué elegir Glossia

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Enviar continuamente | Las ejecuciones de traducción siguen los cambios de origen y devuelven actualizaciones de repositorio revisables. El contenido no necesita su propio proceso de lanzamiento independiente. |
| Mantener el control de la implementación | La aplicación pública, la CLI y el código de despliegue pueden ser inspectados y modificados y autoalojados bajo los términos de la licencia. |
| Traiga sus propios tokens | Configure modelos soportados con sus propios tokens de API del proveedor. Los archivos del repositorio hacen referencia a manejadores de modelo estables, no a secretos. |
| Reutilice las comprobaciones que confían | Ejecuta un comando de validación de repositorio contra el candidato en su ruta de destino real antes de aceptarlo. |
| Mantenga el contenido suyo | Archivos de origen, salidas traducidas, configuración e historial de solicitudes de extracción permanecen en su repositorio. |

## Localización que se mantiene al día con los commits

Glossia funciona desde instrucciones `L10N.md` versionadas y detecta qué contenido necesita actualización. Las entradas sin cambios no necesitan ser traducidas nuevamente. Un proyecto mantiene una única solicitud de extracción de traducción abierta y publica el progreso por lotes, reduciendo solicitudes de extracción innecesarias y ejecuciones CI repetidas conforme evoluciona el origen.

El resultado es un flujo de trabajo de idioma diseñado alrededor de los mismos cambios pequeños y revisables que su equipo ya distribuye. Continuo no significa sin revisar: los revisores aún deciden qué es seguro para fusionar.

Crowdin también soporta integraciones de Git y automatización. La razón para elegir Glossia no es que Crowdin no pueda conectarse a un repositorio, sino que la entrega del repositorio es la base del flujo de trabajo de Glossia, no solo un límite de integración.

## Sus tokens, sus elecciones de modelo

No debería tener que reconstruir la configuración del repositorio para rotar un token del proveedor o cambiar el modelo detrás de un flujo de traducción. Glossia almacena credenciales en la configuración de la cuenta y expone manejadores estables al repositorio. Áreas de contenido diferentes o localizaciones objetivo pueden seleccionar modelos configurados diferentes.

Esto le da a su equipo control sobre las relaciones de proveedor soportadas y las elecciones del modelo que utiliza. Consulte [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide la salida como parte de su producto

Una traducción puede leerse correctamente y aún así romper una compilación de documentación, un componente, un marcador de posición o un analizador de aplicación. Glossia le permite reutilizar una comprobación del repositorio en lugar de detenerse en la evaluación de un editor del texto.

Si su repositorio ya proporciona un guion de validación de documentación, refiérase directamente a él:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

El validador recibe el candidato en su ruta de destino real, devuelve un estado no nulo en caso de fallo y se ejecuta dentro del límite de reintento configurado. Sus dependencias deben estar disponibles en el entorno de validación. Consulte [L10N.md](/docs/reference/l10n-md) para el contrato.

## Fuentes públicas, sin ceder el repositorio

Puede inspeccionar cómo funcionan los planes de Glossia, cómo maneja las credenciales, cómo preserva el Markdown y cómo valida un resultado. Los archivos traducidos existentes permanecen publicables a través del pipeline de su repositorio incluso si el servicio de idioma no está disponible.

Glossia está disponible en código fuente bajo la [licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), lo cual permite autoalojar, pero restringe servicios alojados competidores. No es una licencia de código abierto sin restricciones.

Crowdin aún puede ser apropiado para un programa centrado en la coordinación de contribuyentes y un editor de traducción dedicado. Para un equipo de software cuya prioridad es **contenido propiedad de Git, validación existente y localización que sigue la entrega**, Glossia está diseñado para ese trabajo.

Esta comparación no afirma que Crowdin carezca de automatización o cualquier forma de integración del proveedor, ni que Glossia migre automáticamente sus memorias e historia. Consulte [documentación de Crowdin](https://support.crowdin.com/) para las capacidades actuales.
