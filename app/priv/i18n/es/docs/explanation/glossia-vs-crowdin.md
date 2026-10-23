%{
  title: "Glossia frente a Crowdin",
  summary:
    "Elige Glossia para mantener la localización en Git, llevar tus propios tokens de modelo y validar con las comprobaciones de tu repositorio.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Elige Glossia cuando la localización necesite moverse a la velocidad de la entrega de tu software.** Tu repositorio ya define cómo se revisan, validan y se despliegan los cambios. Glossia integra el trabajo de idioma en ese ciclo en lugar de convertir un espacio de trabajo de traducción independiente en el centro de tu proceso.

[Crowdin](https://crowdin.com/) proporciona la gestión colaborativa de traducción, flujos de trabajo de revisión, memorias de traducción e integraciones de repositorio. La ventaja de Glossia para un equipo de software es la combinación de contenido propiedad del repositorio, fuente inspectable, tus propias credenciales de modelo y validación que comprende el proyecto real.

## ¿Por qué elegir Glossia?

| Tu prioridad | La ventaja de Glossia |
|---|---|
| Entrega continuamente | Las ejecuciones de traducción siguen los cambios del origen y devuelven actualizaciones del repositorio revisables. El contenido no necesita un proceso de lanzamiento independiente sin relación. |
| Mantén el control de la implementación | La aplicación pública, la CLI y el código de despliegue pueden inspeccionarse, modificarse y auto-alojarse bajo los términos de licencia. |
| Lleva tus propios tokens | Configura modelos compatibles con tus propios tokens de API del proveedor. Los archivos del repositorio hacen referencia a manejadores de modelo estables, no a secretos. |
| Reutiliza los controles que confías | Ejecuta un comando de validación del repositorio contra el candidato en su ruta de destino real antes de aceptarlo. |
| Mantén el contenido tuyo | Los archivos del origen, las salidas traducidas, la configuración y el historial de solicitudes de extracción permanecen en tu repositorio. |

## Localización que se mantiene al día con los commits

Glossia funciona a partir de instrucciones versionadas `L10N.md` y detecta qué contenido necesita actualización. Las entradas sin cambios no necesitan ser traducidas nuevamente. Un proyecto mantiene una solicitud de extracción de traducción abierta y publica el progreso por lotes, reduciendo solicitudes de extracción innecesarias y ejecuciones repetidas de CI a medida que el origen evoluciona.

El resultado es un flujo de trabajo de idioma diseñado alrededor de los mismos pequeños cambios revisables que tu equipo ya entrega. Continuo no significa sin revisión: los revisores aún deciden qué es seguro fusionar.

Crowdin también soporta integraciones de Git y automatización. La razón para elegir Glossia no es que Crowdin no pueda conectarse a un repositorio; es que la entrega del repositorio es la base del flujo de trabajo de Glossia, no solo un límite de integración.

## Tus tokens, tus elecciones de modelo

No debes tener que volver a construir la configuración del repositorio para rotar un token del proveedor o cambiar el modelo detrás de un flujo de trabajo de traducción. Glossia almacena las credenciales en la configuración de la cuenta y expone identificaciones estables al repositorio. Diferentes áreas de contenido o idiomas destino pueden seleccionar diferentes modelos configurados.

Esto da a tu equipo control sobre las relaciones de proveedor soportadas y las elecciones de modelo que usa. Consulta [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Valida la salida como parte de tu producto

Una traducción puede redactarse bien y aún así romper un build de documentación, un componente, un marcador de posición o un analizador de aplicación. Glossia te permite reutilizar una verificación del repositorio en lugar de detenerte en una evaluación del editor del texto.

Si tu repositorio ya proporciona un script de validación de documentación, menciona directamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

El validador recibe al candidato en su ruta de destino real, devuelve un estado no nulo en caso de error y se ejecuta dentro del presupuesto de reintento configurado. Sus dependencias deben estar disponibles en el entorno de validación. Ver [L10N.md](/docs/reference/l10n-md) para el contrato.

## Fuente pública, sin ceder el repositorio

Puedes inspeccionar cómo funcionan los planes de Glossia, manejan las credenciales, preservan Markdown y validan un resultado. Los archivos traducidos existentes permanecen publicables a través del pipeline de tu repositorio incluso si el servicio de idioma no está disponible.

Glossia está disponible bajo la licencia Source-available de la [O'Saasy license](https://github.com/glossia/glossia/blob/main/LICENSE.md), lo cual permite el autoalojamiento pero restringe los servicios competidores alojados. No es una licencia de código abierto sin restricciones.

Crowdin aún puede ser adecuado para un programa centrado en la coordinación de colaboradores y un editor de traducción dedicado. Para un equipo de software cuya prioridad es **el contenido propiedad de Git, la validación existente y la localización que sigue la entrega**, Glossia está diseñado para ese trabajo.

Esta comparación no afirma que Crowdin carezca de automatización o de toda forma de integración del proveedor, o que Glossia migre automáticamente sus memorias e historial. Consulta [Crowdin's documentation](https://support.crowdin.com/) para las capacidades actuales.
