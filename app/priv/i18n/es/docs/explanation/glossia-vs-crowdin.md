%{
  title: "Glossia vs Crowdin",
  summary:
    "Elige Glossia para mantener la localización en Git, traer tus propios tokens de modelo y validar con las verificaciones de tu repositorio.",
  category: "explicación",
  markdown_only: true,
  section: "translation",
  order: 20
}
---

**Elija Glossia cuando la localización necesite avanzar a la velocidad de su ciclo de entrega del software.** Su repositorio ya define cómo se revisan, validan y publican los cambios. Glossia incorpora el trabajo de idioma en ese ciclo en lugar de convertir un espacio de trabajo de traducción separado en el centro de su proceso.

[Crowdin](https://crowdin.com/) proporciona gestión de traducción colaborativa, flujos de trabajo de revisión, memorias de traducción e integraciones con repositorios. La ventaja de Glossia para un equipo de software es la combinación de contenido propiedad del repositorio, código fuente inspeccionable, sus propias credenciales del modelo y validación que entiende el proyecto real.

## ¿Por qué elegir Glossia?

| Su prioridad | Ventaja de Glossia |
|---|---|
| Publicar continuamente | Las ejecuciones de traducción siguen los cambios del código fuente y devuelven actualizaciones del repositorio revisables. El contenido no necesita su propio proceso de lanzamiento independiente. |
| Mantenga el control de la implementación | La aplicación pública, la CLI y el código de despliegue pueden ser inspeccionados, modificados y autoalojados bajo los términos de la licencia. |
| Traiga sus propios tokens | Configure los modelos admitidos con sus propios tokens de API de proveedor. Los archivos del repositorio hacen referencia a identificadores de modelo estables, no a secretos. |
| Reutilice las verificaciones que confía | Ejecute un comando de validación del repositorio contra el candidato en su ruta de destino real antes de aceptarlo. |
| Llame al contenido suyo | Los archivos del código fuente, las salidas traducidas, la configuración y el historial de solicitudes de extracción permanecen en su repositorio. |

## Localización que se mantiene al día con los commits

Glossia trabaja a partir de `L10N.md` instrucciones versionadas y detecta qué contenido necesita actualización. Las entradas sin cambios no necesitan ser traducidas nuevamente. Un proyecto mantiene una única solicitud de extracción de traducción abierta y publica el progreso en lotes, reduciendo solicitudes de extracción innecesarias y ejecuciones repetidas de CI a medida que evoluciona el código fuente.

El resultado es un flujo de trabajo de idioma diseñado alrededor de los mismos pequeños cambios revisables que su equipo ya publica. Continuamente no significa sin revisar: los revisores aún deciden qué es seguro fusionar.

Crowdin también admite integraciones con Git y automatización. La razón para elegir Glossia no es que Crowdin no pueda conectarse a un repositorio; es que la entrega del repositorio es la base del flujo de trabajo de Glossia, no solo un límite de integración.

## Sus tokens, sus elecciones de modelo

No debería tener que reconstruir la configuración del repositorio para rotar un token del proveedor o cambiar el modelo detrás de un flujo de trabajo de traducción. Glossia almacena credenciales en las configuraciones de la cuenta y expone identificadores estables al repositorio. Diferentes áreas de contenido o variantes de destino pueden seleccionar modelos configurados diferentes.

Esto da a su equipo control sobre las relaciones de proveedor admitidas y las opciones de modelo que utiliza. Consulte [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider).

## Valide el resultado como parte de su producto

Una traducción puede leerse bien y aún así romper una construcción de documentación, un componente, un marcador de posición o un analizador de aplicación. Glossia le permite reutilizar una verificación del repositorio en lugar de detenerse en la evaluación de un editor del texto.

Si su repositorio ya proporciona un script de validación de documentación, refiérase a él directamente:

```yaml
validation:
  - ./scripts/validate-docs.sh
  - --strict
```

El validador recibe el candidato en su ruta de destino real, devuelve un estado distinto de cero al fallar y se ejecuta dentro del presupuesto de reintento configurado. Sus dependencias deben estar disponibles en el entorno de validación. Consulte [L10N.md](/docs/reference/l10n-md) para el contrato.

## Código fuente público, sin entregar el repositorio

Puede inspeccionar cómo funcionan los planes de Glossia, maneja las credenciales, conserva el Markdown y valida un resultado. Los archivos traducidos existentes siguen siendo publisables a través del pipeline de su repositorio incluso si el servicio de idioma no está disponible.

Glossia es código abierto: [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE) cubre el núcleo y permite el autoalojamiento y servicios alojados competidores. El código empresarial de código fuente disponible bajo `ee/` tiene una [licencia](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) separada que requiere un acuerdo comercial por escrito para uso en producción.

Crowdin aún puede ser adecuado para un programa centrado en la coordinación de contribuyentes y un editor de traducción dedicado. Para un equipo de software cuya prioridad es **contenido propio de Git, validación existente y localización que sigue la entrega**, Glossia está diseñado para ese trabajo.

Esta comparación no afirma que Crowdin carezca de automatización o de cada forma de integración del proveedor, ni que Glossia migre automáticamente sus memorias e historial. Consulte [la documentación de Crowdin](https://support.crowdin.com/) para las capacidades actuales.
