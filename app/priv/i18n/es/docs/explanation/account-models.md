%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian por handle.",
  category: "explicación",
  section: "platform",
  order: 2
}
---

Glossia separa las instrucciones del repositorio de las credenciales del proveedor del modelo. Los repositorios describen lo que debe ser traducido, mientras las cuentas deciden qué [modelo de lenguaje a gran escala](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## ## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con el proveedor. Los modelos con alcance de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un identificador legible como `translation-default`, no la clave del proveedor.

## ## Los identificadores proporcionan una intención estable

El campo `model` en `L10N.md` hace referencia a un identificador de modelo de cuenta:

```yaml
model: translation-default
```

El identificador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo de proveedor selecciona dicho identificador mientras la configuración del repositorio se mantiene estable.

## ## Cómo se utilizan varios modelos

Glossia utiliza un modelo **generativo** configurado para la traducción de cada documento. Añadir varios modelos no crea un conjunto, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de identificadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y la localización objetivo:

1. El archivo `L10N/<locale>.md` más cercano que declara `model` gana para esa localización.
2. Por otro lado, el archivo `L10N.md` más cercano que declara `model` gana para su directorio.
3. La configuración `L10N.md` de los padres se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un identificador, Glossia utiliza el modelo generativo predeterminado de la cuenta.

Debe existir un identificador configurado explícitamente. Glossia reporta un error para un identificador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## ## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que el repositorio tenga su propio `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo añadido a cada categoría se convierte en el predeterminado de esa categoría, y un administrador puede hacer que otro modelo sea el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usar un identificador explícito hace que su elección sea clara para los revisores. Omitir `model` mantiene al repositorio en el predeterminado de la cuenta.

## ## Modelos generativos y de decisión

Las configuraciones de modelo tienen dos categorías:

- Los modelos **Generativo** escriben las traducciones e impulsan la configuración del proyecto. Los identificadores de modelo de repositorio y las reglas de enrutamiento de localización seleccionan solo esta categoría.
- Los modelos **Decisión** evalúan las traducciones contra una rúbrica de calidad fija. Cuando una cuenta tiene un modelo de decisión, su modelo de decisión predeterminado revisa automáticamente cada documento de repositorio traducido después de la validación estructural y las traducciones completas y de un solo documento desde el endpoint de contenido. Las solicitudes fragmentadas son primitivas de generación; las ejecuciones del repositorio evalúan su salida ensamblada.

Las categorías tienen predeterminados independientes. Añadir Jev nunca cambia el modelo que escribe sus traducciones. El primer modelo de decisión habilita la evaluación para las subsecuentes ejecuciones de traducción; eliminar la última deshabilita la evaluación. Las cuentas sin modelos de decisión mantienen su comportamiento existente.

Glossia actualmente admite [TypeSafe Jev](https://docs.typesafe.ai/introduction) como proveedor de decisiones. Jev devuelve elecciones y puntuaciones predefinidas en lugar de prosa. Glossia convierte las elecciones de debilidad en pistas de corrección, sin presentarlas como errores localizados o verificados independientemente.

## ## Verificaciones de calidad y revisiones

El evaluador recibe la fuente, la traducción, la localización objetivo, el formato de contenido, las instrucciones del proyecto y el contexto de la organización resuelto. Evalúa la preservación del sentido, la completitud, la terminología, la fluidez, la coherencia del documento, el propósito y el ajuste a la audiencia, y la adecuación de la localización. El tono y el registro se evalúan cuando la guía de tono, proyecto o documento está disponible.

Cada dimensión debe alcanzar la puntuación mínima configurada, que predetermina a 7 de 10. Un error mayor o crítico siempre solicita una corrección, independientemente de la puntuación. La confianza se incluye en los eventos de evaluación en vivo y no cambia la aceptación. Estos eventos actualmente no se retienen ni se muestran en el panel de control. Un umbral de 10 requiere una puntuación ponderada perfecta y suele ser demasiado estricto.

Las dimensiones fallidas alimentan sus pistas de corrección predefinidas en el intento de traducción siguiente. El conjunto de configuración existente del repositorio `retries` limita estas revisiones; el endpoint de contenido permite tres reintentos de corrección, configurables de cero a tres con su campo `retries`. El documento revisado completo pasa nuevamente las comprobaciones estructurales y la evaluación de calidad antes de ser aceptado.

Los fallos del proveedor transitorios se reintentan con retardo exponencial hasta tres veces; las credenciales inválidas y las respuestas malformadas fallan inmediatamente. Los fallos del proveedor agotados detienen la traducción del archivo; la salida no verificada nunca se acepta. Las evaluaciones usan documentos completos y la entrada de evaluación de tamaño excesivo se rechaza en lugar de truncarse. La entrada serializada se limita conservadoramente a 30,000 bytes para el estado más la pregunta más larga, y 60,000 bytes en la solicitud completa, para permanecer dentro de los [límites de contexto de Jev](https://docs.typesafe.ai/models). Las puntuaciones automatizadas son juicios del modelo y todavía requieren calibración contra la revisión humana bilingüe.

La configuración del evaluador y la versión de la rúbrica participan en los archivos de bloqueo de traducción. Habilitar la evaluación, cambiar modelos o umbrales, o eliminar la evaluación hace que las traducciones anteriores sean obsoletas para la próxima ejecución. Las claves del proveedor están excluidas de los archivos de bloqueo.

## ## El límite de la revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras los cambios del repositorio se publican a través de una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.
