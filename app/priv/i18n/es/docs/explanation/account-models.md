%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante su manejador.",
  category: "explicación",
  section: "platform",
  order: 2
}
---
Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden cuál [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con el proveedor. Los modelos con alcance de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una sola vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un identificador legible, tal como `translation-default`, no la clave del proveedor.

## Los identificadores proporcionan una intención estable

El `model` campo en `L10N.md` hace referencia a un identificador de modelo de cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo de proveedor selecciona dicho identificador mientras la configuración del repositorio se mantiene estable.

## Cómo se utilizan varios modelos

Glossia utiliza uno configurado **generativa** modelo para cada traducción de documento. Añadir varios modelos no crea un conjunto, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito mediante identificadores estables tales como `translation-default`, `long-form`, o `japanese-specialist`.

La selección sigue la jerarquía de contexto del documento y el idioma de destino:

1. El más cercano `L10N/<locale>.md` archivo que declara `model` prevalece para esa localización.
2. De lo contrario, el más cercano `L10N.md` archivo que declara `model` prevalece para su directorio.
3. Padre `L10N.md` las configuraciones se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declare un manejador, Glossia utiliza el modelo generativo predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia informa un error ante un manejador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga el suyo `L10N.md`. Glossia, por lo tanto, selecciona el predeterminado de la cuenta. El primer modelo añadido a cada categoría se convierte en el predeterminado de esa categoría y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usar un manejador explícito hace que su elección quede clara para revisores. Omitir `model` mantiene el repositorio en el predeterminado de la cuenta.

## Modelos generativos y de decisión

Las configuraciones del modelo tienen dos categorías:

- **Generativos** los modelos escriben traducciones e impulsan la configuración del proyecto. Los manejadores de modelo de repositorio y las reglas de enrutamiento de localización seleccionan únicamente esta categoría.
- **Decisión** Los modelos evalúan las traducciones contra una rúbrica de calidad fija. Cuando una cuenta tiene un modelo de decisiones, su modelo de decisiones predeterminado verifica automáticamente cada documento del repositorio traducido después de la validación estructural y tras traducciones completas de un solo documento desde el endpoint de contenido. Las solicitudes de fragmentos son primitivas de generación; las ejecuciones del repositorio evalúan su salida ensamblada.

Las categorías tienen valores predeterminados independientes. Añadir Jev nunca cambia el modelo que escribe sus traducciones. El primer modelo de decisiones habilita la evaluación para las subsiguientes ejecuciones de traducción; eliminar el último inhabilita la evaluación. Las cuentas sin modelos de decisiones conservan su comportamiento existente.

Glossia actualmente soporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como proveedor de decisiones. Jev devuelve opciones y puntuaciones predefinidas en lugar de prosa. Glossia convierte las opciones de debilidad en sugerencias de corrección, sin presentarlas como errores ubicados o verificados de forma independiente.

## Comprobaciones de calidad y revisiones

El evaluador recibe la fuente, traducción, idioma objetivo, formato de contenido, instrucciones del proyecto y contexto de organización resuelto. Evalúa la preservación del significado, la completitud, la terminología, la fluidez, la coherencia del documento, el ajuste al propósito y audiencia, y la idoneidad de la localización. Se evalúa la voz y el registro cuando hay orientación disponible en voz, proyecto o documento.

Cada dimensión debe alcanzar la puntuación mínima configurada, que por defecto es 7 sobre 10. Un error mayor o crítico siempre solicita corrección, independientemente de la puntuación. La confianza está incluida en los eventos de evaluación en vivo y no cambia la aceptación. Estos eventos actualmente no se retienen ni se muestran en el panel de control. Un umbral de 10 requiere una puntuación ponderada perfecta y es usualmente demasiado estricto.

Las dimensiones fallidas proporcionan sus pistas de corrección predeterminadas a los intentos de traducción siguientes. La configuración existente de `retries` del repositorio limita estas revisiones; el endpoint de contenido permite tres reintentos de corrección, configurables desde cero hasta tres mediante su campo `retries`. El documento revisado completo cumple las verificaciones estructurales y la evaluación de calidad nuevamente antes de ser aceptado.

Los fallos transitorios del proveedor reintentan con retraso exponencial hasta tres veces; las credenciales inválidas y las respuestas malformadas fallan inmediatamente. Los fallos por agotamiento del proveedor detienen la traducción del archivo; la salida sin verificar nunca es aceptada. Las evaluaciones utilizan documentos completos, y la entrada de evaluación de tamaño excesivo es rechazada en lugar de truncada. La entrada serializada se limita conservadoramente a 30.000 bytes para el estado más la pregunta más larga, y 60.000 bytes a lo largo de la solicitud completa, para permanecer dentro de [Límites de contexto de Jev](https://docs.typesafe.ai/models). Las puntuaciones automáticas son juicios del modelo y aún requieren calibración contra la revisión humana bilingüe.

La configuración del evaluador y la versión de la rúbrica participan en los archivos de bloqueo de traducción. Habilitar la evaluación, cambiar modelos o umbrales, o eliminar la evaluación hace que las traducciones anteriores queden obsoletas para la siguiente ejecución. Las claves del proveedor se excluyen de los archivos de bloqueo.

## El límite de la revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican mediante una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.