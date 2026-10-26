%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian mediante handle.",
  category: "explicación",
  section: "platform",
  order: 2
}
---

Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden qué [gran modelo de lenguaje](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación con el proveedor. Los modelos con ámbito de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar todos los repositorios.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un manejador legible como `translation-default`, no la clave del proveedor.

## Los manejadores proporcionan una intención estable

El campo `model` del `L10N.md` se refiere a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar más tarde qué modelo del proveedor selecciona ese manejador mientras la configuración del repositorio permanece estable.

## Cómo se usan varios modelos

Glossia utiliza un único modelo **generativo** configurado para cada traducción de documento. Añadir varios modelos no crea un ensemble, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y la localidad objetivo:

1. El archivo `L10N/<locale>.md` más cercano que declara `model` gana para esa localidad.
2. De lo contrario, el archivo `L10N.md` más cercano que declara `model` gana para su directorio.
3. Las configuraciones `L10N.md` parentales se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia utiliza el modelo generativo predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia reporta un error para un manejador desconocido en lugar de cambiar silenciosamente al modelo predeterminado de la cuenta.

## Selección predeterminada

El establecimiento del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo agregado a cada categoría se convierte en el predeterminado de esa categoría, y un administrador puede establecer otro modelo como predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, el uso de un manejador explícito hace clara su selección para los revisores. Omitir `model` mantiene al repositorio en el predeterminado de la cuenta.

## Modelos generativos y de decisión

Las configuraciones de modelos tienen dos categorías:

- Los modelos **Generativos** escriben traducciones y alimentan el establecimiento del proyecto. Los manejadores de modelos del repositorio y las reglas de enrutamiento de la localidad seleccionan solo esta categoría.
- Los modelos **Decisión** evalúan las traducciones contra una rúbrica de calidad fija. Cuando una cuenta tiene un modelo de decisión, su modelo de decisión predeterminado verifica automáticamente cada documento del repositorio traducido después de la validación estructural y las traducciones completas de un solo documento desde el endpoint de contenido. Las solicitudes de fragmentos son primitivas de generación; las ejecuciones del repositorio evalúan su salida ensamblada.

Las categorías tienen predeterminados independientes. Agregar Jev nunca cambia el modelo que escribe sus traducciones. El primer modelo de decisión habilita la evaluación para las subsiguientes ejecuciones de traducción; eliminar el último deshabilita la evaluación. Las cuentas sin modelos de decisión mantienen su comportamiento existente.

Glossia actualmente soporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como proveedor de decisiones. Jev devuelve selecciones predefinidas y puntuaciones en lugar de prosa. Glossia convierte las selecciones de debilidad en señales de corrección, sin presentarlas como errores ubicados o verificados de forma independiente.

## Comprobaciones de calidad y revisiones

El evaluador recibe el origen, la traducción, la localización objetivo, el formato de contenido, las instrucciones del proyecto y el contexto de organización resuelto. Evalúa la preservación del significado, la completitud, la terminología, la fluidez, la coherencia del documento, la adecuación del propósito y la audiencia, y la idoneidad de la localización. La voz y el registro se evalúan cuando está disponible la guía de voz, proyecto o documento.

Cada dimensión debe alcanzar la puntuación mínima configurada, que por defecto es 7 de 10. Un error importante o crítico siempre solicita corrección, independientemente de la puntuación. La confianza se incluye en los eventos de evaluación en tiempo real y no cambia la aceptación. Estos eventos actualmente no se conservan ni se muestran en el tablero. Un umbral de 10 requiere una puntuación ponderada perfecta y usualmente es demasiado estricto.

Las dimensiones fallidas alimentan sus señales de corrección predefinidas en el siguiente intento de traducción. La configuración `retries` existente del repositorio limita estas revisiones; el endpoint de contenido permite tres reintentos de corrección, configurables de cero a tres con su campo `retries`. El documento revisado completo pasa las comprobaciones estructurales y la evaluación de calidad nuevamente antes de ser aceptado.

Los errores transitorios del proveedor se reintentan con retraso exponencial hasta tres veces; las credenciales inválidas y las respuestas mal formadas fallan inmediatamente. Los errores del proveedor agotados detienen la traducción del archivo; la salida sin verificar nunca es aceptada. Las evaluaciones utilizan documentos completos, y la entrada de evaluación demasiado grande es rechazada en lugar de truncada. La entrada seriada se limita conservadoramente a 30,000 bytes para el estado más la pregunta más larga, y a 60,000 bytes en toda la solicitud completa, para permanecer dentro de [límites de contexto de Jev](https://docs.typesafe.ai/models). Las puntuaciones automatizadas son evaluaciones de modelos y aún requieren calibración contra una revisión humana bilingüe.

La configuración del evaluador y la versión de la rúbrica participan en los archivos de bloqueo de traducción. Habilitar la evaluación, cambiar modelos o umbrales, o eliminar la evaluación hace que las traducciones anteriores se vuelvan obsoletas para la próxima ejecución. Las claves de proveedor están excluidas de los archivos de bloqueo.

## El límite de la revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de establecimiento y traducción permanece visible en Glossia, mientras los cambios del repositorio se publican mediante un pull request para que el equipo lo revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.
