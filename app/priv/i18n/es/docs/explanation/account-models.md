%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se hacen referencia por su identificador.",
  category: "explicación",
  section: "platform",
  order: 2
}
---

Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen lo que debe traducirse, mientras que las cuentas deciden qué [gran modelo de lenguaje](https://en.wikipedia.org/wiki/Large_language_model) realiza el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo a menudo traduce varios repositorios con la misma relación de proveedor. Los modelos de ámbito de cuenta permiten a los administradores rotar una clave del proveedor o cambiar el modelo subyacente una vez sin editar cada repositorio.

Este límite también mantiene las credenciales fuera del control de fuentes. Un repositorio contiene un nombre legible como `translation-default`, no la clave del proveedor.

## Las manijas proporcionan intención estable

El campo `model` en `L10N.md` se refiere a la manija de modelo de la cuenta:

```yaml
model: translation-default
```

La manija expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo del proveedor selecciona dicha manija mientras la configuración del repositorio se mantiene estable.

## Cómo se utilizan varios modelos

Glossia utiliza un modelo **generativo** configurado para cada traducción de documento. Agregar varios modelos no crea un ensamble, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manijas estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el destino local:

1. El archivo `L10N/<locale>.md` más cercano que declara `model` gana para ese destino local.
2. Por el contrario, el archivo `L10N.md` más cercano que declara `model` gana para su directorio.
3. La configuración de `L10N.md` de los archivos padres se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara una manija, Glossia utiliza el modelo generativo predeterminado de la cuenta.

Debe existir una manija configurada explícitamente. Glossia reporta un_error para una manija desconocida en lugar de cambiar silenciosamente al predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Por lo tanto, Glossia selecciona el predeterminado de la cuenta. El primer modelo añadido a cada categoría se convierte en el predeterminado de esa categoría, y un administrador puede hacer de otro modelo el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`, usar una manija explícita hace clara su elección para los revisores. Omitir `model` mantiene el repositorio en el predeterminado de la cuenta.

## Modelos generativos y de decisión

Las configuraciones de los modelos tienen dos categorías:

- Los **Generativo** escriben traducciones y propulsan la configuración del proyecto. Las manijas de modelo del repositorio y las reglas de ruta de destino seleccionan solo esta categoría.
- Los **Decisión** evalúan las traducciones frente a un rubrica de calidad fijo. Cuando una cuenta tiene un modelo de decisión, su modelo de decisión predeterminado verifica automáticamente cada documento de repositorio traducido después de la validación estructural y las traducciones completas de un solo documento desde el endpoint de contenido. Las solicitudes de fragmento son primitivas de generación; las ejecuciones del repositorio evalúan su salida ensamblada.

Las categorías tienen predeterminados independientes. Añadir Jev nunca cambia el modelo que escribe sus traducciones. El primer modelo de decisión habilita la evaluación para las ejecuciones de traducción subsiguientes; eliminar la última deshabilita la evaluación. Las cuentas sin modelos de decisión mantienen su comportamiento existente.

Glossia actualmente soporta [TypeSafe Jev](https://docs.typesafe.ai/introduction) como proveedor de decisión. Jev devuelve elecciones y puntuaciones predefinidas en lugar de texto. Glossia convierte las elecciones de debilidad en pistas de corrección, sin presentarlas como errores ubicados o verificables independientemente.

## Verificación de calidad y revisiones

El evaluador recibe el origen, la traducción, el destino local, el formato de contenido, las instrucciones del proyecto y el contexto de organización resuelto. Evalúa la preservación del significado, la completitud, la terminología, la fluidez, la coherencia del documento, la adecuación del propósito y público, y la adecuación del destino local. La voz y el registro se evalúan cuando está disponible la orientación de voz, proyecto o documento.

Cada dimensión debe alcanzar la puntuación mínima configurada, que predesigna a 7 sobre 10. Un error mayor o crítico siempre solicita corrección, independientemente de la puntuación. La confianza se incluye en los eventos de evaluación en vivo y no cambia la aceptación. Estos eventos actualmente no se retienen ni se muestran en el tablero. Un umbral de 10 exige una puntuación ponderada perfecta y suele ser demasiado estricto.

Las dimensiones fallidas inyectan sus pistas de corrección predefinidas en el intento de traducción siguiente. El ajuste `retries` existente del repositorio acota estas revisiones; el endpoint de contenido permite tres intentos de corrección, configurable de cero a tres con su `retries`. El documento revisado completo pasa nuevamente las comprobaciones estructurales y la evaluación de calidad antes de ser aceptado.

Las fallas transitorias del proveedor se repiten con backoff exponencial hasta tres veces; las credenciales inválidas y las respuestas malformadas fallan inmediatamente. Las fallas del proveedor agotadas detienen la traducción del archivo; la salida sin comprobar nunca se acepta. Las evaluaciones utilizan documentos completos, y la entrada de evaluación oversized se rechaza en lugar de truncada. La entrada serializada se limita conservadoramente a 30.000 bytes para el estado y la pregunta más larga, y 60.000 bytes en toda la solicitud, para mantenerse dentro de [límites de contexto de Jev](https://docs.typesafe.ai/models). Las puntuaciones automáticas son juicios del modelo y aún requieren calibración contra la revisión humana bilingüe.

La configuración del evaluador y la versión de la rúbrica participan en los archivos de bloqueo de traducción. Habilitar la evaluación, cambiar modelos o umbrales, o eliminar la evaluación hace que las traducciones previas estén caducadas para la próxima ejecución. Las claves de proveedor se excluyen de los archivos de bloqueo.

## El límite de la revisión humana

La salida del modelo es trabajo propuesto, no una fusión automática. La actividad de configuración y traducción permanece visible en Glossia, mientras que los cambios del repositorio se publican a través de una pull request para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya usan para el código.
