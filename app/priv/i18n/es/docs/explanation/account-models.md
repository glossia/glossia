%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian por handle.",
  category: "explicación",
  section: "platform",
  order: 2
}
---

Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelo. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden qué [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo suele traducir varios repositorios con la misma relación con el proveedor. Los modelos de ámbito de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una sola vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de origen. Un repositorio contiene un manejador legible como `translation-default`, no la clave del proveedor.

## Los manejadores proporcionan una intención estable

El campo `model` en `L10N.md` se refiere a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar más tarde qué modelo de proveedor selecciona ese manejador mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia utiliza un **generativo** configurado para cada traducción de documento. Añadir varios modelos no crea un ensamble, una cadena de reemplazo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form`, o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el idioma objetivo:

1. El archivo `L10N/<locale>.md` más cercano que declare `model` prevalece para ese idioma.
2. De lo contrario, el archivo `L10N.md` más cercano que declare `model` prevalece para su directorio.
3. Los ajustes de `L10N.md` de los padres se heredan cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declare un manejador, Glossia usa el modelo generativo predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia informa un error para un manejador desconocido en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo añadido a cada categoría se convierte en el predeterminado de esa categoría, y un administrador puede establecer otro modelo como predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, el uso de un manejador explícito hace que su elección sea clara para los revisores. Omitir `model` mantiene al repositorio en el predeterminado de la cuenta.

## Modelos generativos y de decisión

Las configuraciones de modelos tienen dos categorías:

- Los modelos **Generativos** escriben traducciones y potencian la configuración del proyecto. Los manejadores de modelos del repositorio y las reglas de enrutamiento de idioma seleccionan solo esta categoría.
- Los modelos **Decisión** evalúan las traducciones frente a una rúbrica de calidad fija. Cuando una cuenta tiene un modelo de decisión, su modelo de decisión predeterminado verifica automáticamente cada documento del repositorio traducido tras la validación estructural y las traducciones completas de documentos individuales desde el endpoint de contenido. Las solicitudes de fragmento son primitivas de generación; las ejecuciones del repositorio evalúan su salida ensamblada.

Las categorías tienen predeterminados independientes. Añadir Jev nunca cambia el modelo que escribe tus traducciones. El primer modelo de decisión habilita la evaluación para las siguientes ejecuciones de traducción; eliminar el último deshabilita la evaluación. Las cuentas sin modelos de decisión mantienen su comportamiento existente.

Glossia actualmente soporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como proveedor de decisiones. Jev devuelve opciones predefinidas y puntuaciones en lugar de texto. Glossia convierte las opciones de debilidad en pistas de corrección, sin presentarlas como errores localizados o independientemente verificados.

## Comprobaciones de calidad y revisiones

El evaluador recibe el origen, la traducción, el idioma objetivo, el formato de contenido, las instrucciones del proyecto y el contexto de organización resuelto. Evalúa la preservación del significado, la completitud, la terminología, la fluidez, la coherencia del documento, la adecuación del propósito y la audiencia, y la adecuación del idioma. La voz y el registro se evalúan cuando está disponible la guía de voz, proyecto o documento.

Cada dimensión debe alcanzar la puntuación mínima configurada, que por defecto es 7 de 10. Un error mayor o crítico siempre solicita corrección, independientemente de la puntuación. La confianza se incluye en los eventos de evaluación en vivo y no cambia la aceptación. Estos eventos actualmente no se conservan o muestran en el panel de control. Un umbral de 10 requiere una puntuación ponderada perfecta y usualmente es demasiado estricto.

Las dimensiones fallidas aportan sus pistas de corrección predefinidas al siguiente intento de traducción. La configuración `retries` existente del repositorio limita estas revisiones; el endpoint de contenido permite tres intentos de corrección, configurables de cero a tres con su campo `retries`. El documento revisado completo pasa nuevamente las comprobaciones estructurales y la evaluación de calidad antes de ser aceptado.

Los fallos del proveedor transitorios se reintentan con retraso exponencial hasta por tres veces; las credenciales inválidas y las respuestas malformadas fallan inmediatamente. Los fallos agotados del proveedor detienen la traducción del archivo; la salida sin verificar nunca se acepta. Las evaluaciones usan documentos completos y la entrada de evaluación de tamaño excesivo se rechaza en lugar de truncarse. La entrada serializada se limita conservadoramente a 30,000 bytes para el estado más la pregunta más larga, y 60,000 bytes en toda la solicitud, para mantenerse dentro de [los límites de contexto de Jev](https://docs.typesafe.ai/models). Las puntuaciones automáticas son juicios del modelo y todavía requieren calibración contra la revisión humana bilingüe.

La configuración del evaluador y la versión de la rúbrica participan en los archivos de bloqueo de traducción. Habilitar la evaluación, cambiar modelos o umbrales, o eliminar la evaluación hace que las traducciones previas estén obsoletas para la siguiente ejecución. Las claves de proveedor se excluyen de los archivos de bloqueo.

## El límite de revisión humana

La salida del modelo es un trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican a través de una solicitud de extracción para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya utilizan para el código.
