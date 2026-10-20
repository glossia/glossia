%{
  title: "Glossia frente a Crowdin",
  summary:
    "Elige Glossia para mantener la localización en Git, traer tus propios tokens del modelo y validar con las comprobaciones de tu repositorio.",
  category: "explicación",
  section: "translation",
  order: 20
}
---

**Elige Glossia cuando la localización necesita avanzar a la velocidad de su entrega de software.** Su repositorio ya define cómo se revisan, validan y envían los cambios. Glossia integra la labor lingüística en ese ciclo en lugar de convertir el centro de funcionamiento de su proceso en un espacio de trabajo de traducción separado.

[Crowdin](https://crowdin.com/) proporciona gestión colaborativa de traducción, flujos de trabajo de revisión, memorias de traducción e integraciones de repositorio. La ventaja de Glossia para un equipo de software es la combinación de contenido propiedad del repositorio, fuente inspeccionable, sus propias credenciales del modelo y validación que comprende el proyecto real.

## ¿Por qué elegir Glossia

| Su prioridad | La ventaja de Glossia |
|---|---|
| Entregar continuamente | Las ejecuciones de traducción siguen los cambios en la fuente y devuelven actualizaciones de repositorio revisables. El contenido no necesita un proceso de publicación independiente. |
| Mantenga el control de la implementación | La aplicación pública, la CLI y el código de despliegue pueden revisarse, modificarse y autoalojarse bajo los términos de la licencia. |
| Trae tus propios tokens | Configure modelos admitidos con sus propios tokens de API del proveedor. Los archivos del repositorio apuntan a manejos de modelo estables, no a secretos. |
| Reutilice las comprobaciones que confía | Ejecuta un comando de validación de repositorio contra el candidato en su ruta real de destino antes de aceptarlo. |
| Mantenga su contenido | Los archivos fuente, los resultados traducidos, la configuración e historial de solicitudes de extracción permanecen en su repositorio. |

## Localización que mantiene el ritmo de los commits

Glossia funciona desde las instrucciones versionadas de `L10N.md` y detecta qué contenido necesita actualizarse. Las entradas sin cambios no necesitan traducirse de nuevo. Un proyecto mantiene una solicitud de extracción de traducción abierta y publica el progreso en lotes, reduciendo solicitudes de extracción innecesarias y ejecuciones de CI repetidas a medida que evoluciona la fuente.

El resultado es un flujo de trabajo lingüístico diseñado alrededor de los mismos pequeños cambios revisables que su equipo ya envía. Continuo no significa sin revisión: los revisores aún deciden qué es seguro fusionar.

Crowdin también integra soporte para integraciones con Git y automatización. La razón para elegir Glossia no es que Crowdin no pueda conectarse a un repositorio; el motivo es que la entrega del repositorio es la base del flujo de trabajo de Glossia, no solo un límite de integración.

## Sus tokens, sus elecciones de modelo

No debería tener que reconstruir la configuración del repositorio para rotar un token del proveedor o cambiar el modelo detrás de un flujo de trabajo de traducción. Glossia guarda credenciales en la configuración de la cuenta y expone manejos estables al repositorio. Diferentes áreas de contenido o localizaciones objetivo pueden seleccionar modelos configurados diferentes.

Vea [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide el resultado como parte de su producto

Una traducción puede leerse bien y aún así romper una compilación de documentación, un componente, un marcador de posición o un analizador de aplicaciones. Glossia le permite reutilizar una comprobación de repositorio en lugar de detenerse en la evaluación de un editor del texto.

Si su repositorio ya proporciona un script de validación de documentación, refiérase directamente a él:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

El validador recibe al candidato en su ruta de destino real, devuelve un estado no cero en caso de error y corre dentro del presupuesto de reintento configurado. Sus dependencias deben estar disponibles en el entorno de validación. Consulte [L10N.md](/docs/reference/l10n-md) para el contrato.

## Fuente pública, sin entregar el repositorio

Puede inspeccionar cómo funcionan los planes de Glossia, maneja credenciales, preserva Markdown y valida un resultado. Los archivos traducidos existentes permanecen publicables a través del pipeline de su repositorio incluso si el servicio lingüístico no está disponible.

Glossia está disponible bajo fuente con la [licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), que permite el autoalojamiento pero restringe los servicios alojados competidores. No es una licencia de código abierto sin restricciones.

Crowdin aún puede ser apropiado para un programa centrado en la coordinación de contribuyentes y un editor de traducción dedicado. Para un equipo de software cuya prioridad es **contenido propiedad de Git, validación existente y localización que sigue la entrega**, Glossia está diseñado para ese trabajo.

Esta comparación no afirma que Crowdin carezca de automatización ni de toda forma de integración del proveedor, ni que Glossia migre automáticamente sus memorias e historial. Consulte [Documentación de Crowdin](https://support.crowdin.com/) para las capacidades actuales.
