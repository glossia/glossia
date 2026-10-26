%{
  title: "Modelos de cuenta",
  summary:
    "Por qué los proveedores de modelos se configuran una vez por cuenta y se referencian por handle.",
  category: "explicación",
  section: "platform",
  order: 2
}
---

Glossia separa las instrucciones del repositorio de las credenciales del proveedor de modelos. Los repositorios describen qué debe traducirse, mientras que las cuentas deciden qué [modelo de lenguaje grande](https://en.wikipedia.org/wiki/Large_language_model) ejecuta el trabajo.

## Por qué los modelos pertenecen a las cuentas

Un equipo suele traducir varios repositorios con la misma relación de proveedor. Los modelos con ámbito de cuenta permiten a los administradores rotar una clave de proveedor o cambiar el modelo subyacente una vez sin editar todos los repositorios.

Este límite también mantiene las credenciales fuera del control de versiones. Un repositorio contiene un manejador legible como `translation-default`, no la clave del proveedor.

## Los manejadores proporcionan una intención estable

El campo `model` en `L10N.md` se refiere a un manejador de modelo de cuenta:

```yaml
model: translation-default
```

El manejador expresa la intención del repositorio. Un administrador puede actualizar posteriormente qué modelo de proveedor selecciona dicho manejador mientras la configuración del repositorio permanece estable.

## Cómo se utilizan varios modelos

Glossia usa un modelo **generativo** configurado para cada traducción de documentos. Añadir varios modelos no crea un ensamble, una cadena de respaldo o un nivel de calidad automático. El autor del repositorio elige su propósito a través de manejadores estables como `translation-default`, `long-form` o `japanese-specialist`.

La selección sigue la jerarquía de contexto para el documento y el destino:

1. El archivo `L10N/<locale>.md` más cercano que declara `model` gana para esa localización.
2. De lo contrario, el archivo `L10N.md` más cercano que declara `model` gana para su directorio.
3. La configuración parental `L10N.md` se hereda cuando un archivo más cercano no declara un modelo.
4. Cuando ningún archivo de contexto aplicable declara un manejador, Glossia usa el modelo generativo predeterminado de la cuenta.

Debe existir un manejador configurado explícitamente. Glossia informa un error para un manejador desconocido en lugar de cambiar silenciosamente al valor predeterminado de la cuenta.

## Selección predeterminada

La configuración del proyecto necesita un modelo antes de que un repositorio tenga su propio `L10N.md`. Glossia selecciona, por lo tanto, el modelo predeterminado de la cuenta. El primer modelo añadido a cada categoría se convierte en la categoría, y un administrador puede hacer otro modelo el predeterminado desde su página de configuración.

Una vez que un repositorio tiene `L10N.md`; usar un manejador explícito clarifica su elección para los revisores. Omitir `model` mantiene el repositorio en el predeterminado de la cuenta.

## Modelos generativos y de decisión

Las configuraciones de modelo tienen dos categorías:

- Los modelos **Generativos** escriben traducciones y potencian la configuración del proyecto. Los manejadores de modelos del repositorio y las reglas de enrutamiento de localización solo seleccionan esta categoría.
- Los modelos **Decisión** evalúan traducciones frente a una rúbrica de calidad fijada. Cuando una cuenta tiene un modelo de decisión, su modelo de decisión predeterminado verifica automáticamente cada documento del repositorio traducido después de la validación estructural y las traducciones completas de un solo documento desde el endpoint de contenido. Las solicitudes de fragmento son primitivos de generación; las ejecuciones del repositorio evalúan su salida ensamblada.

Las categorías tienen predeterminados independientes. Añadir Jev nunca cambia el modelo que escribe tus traducciones. El primer modelo de decisión habilita la evaluación para las futuras ejecuciones de traducción; borrar el último deshabilita la evaluación. Las cuentas sin modelos de decisión mantienen su comportamiento actual.

Glossia actualmente admite [TypeSafe Jev](https://docs.typesafe.ai/introduction) como proveedor de decisión. Jev devuelve opciones y puntuaciones predefinidas en lugar de prosa. Glossia convierte las opciones de debilidad en pistas de corrección, sin presentarlas como errores localizados o verificables.

## Verificaciones de calidad y revisiones

El evaluador recibe el origen, la traducción, la localización de destino, el formato de contenido, las instrucciones del proyecto y el contexto de organización resuelto. Evalúa la preservación del significado, completitud, terminología, fluidez, coherencia del documento, coincidencia de propósito y audiencia, y adecuación de la localización. Se evalúa la voz y el registro cuando está disponible la orientación de voz, proyecto o documento.

Cada dimensión debe alcanzar la puntuación mínima configurada, que por defecto es de 7 sobre 10. Un error mayor o crítico siempre solicita corrección, independientemente de la puntuación. La confianza se incluye en los eventos de evaluación en vivo y no cambia la aceptación. Estos eventos actualmente no se retienen o muestran en el cuadro de mando. Un umbral de 10 requiere una puntuación ponderada perfecta y suele ser demasiado estricto.

Las dimensiones fallidas alimentan sus pistas de corrección predefinidas en el siguiente intento de traducción. La configuración existente del repositorio `retries` limita estas revisiones; el endpoint de contenido permite tres reintentos de corrección, configurables de cero a tres con su campo `retries`. El documento revisado completo pasa nuevamente la verificación estructural y la evaluación de calidad antes de ser aceptado.

Los fallos transitorios del proveedor vuelven a intentar con retroceso exponencial hasta tres veces; las credenciales inválidas y las respuestas malformadas fallan inmediatamente. Los fallos exhaustivos del proveedor detienen la traducción del archivo; la salida sin verificar nunca se acepta. Las evaluaciones usan documentos completos, y la entrada de evaluación excesivamente grande se rechaza en lugar de truncarse. La entrada serializada se limita conservadoramente a 30.000 bytes para el estado y la pregunta más larga, y 60.000 bytes en toda la solicitud, para estar dentro de [límites de contexto de Jev](https://docs.typesafe.ai/models). Las puntuaciones automatizadas son juicios del modelo y aún requieren calibración frente a una revisión humana bilingüe.

La configuración del evaluador y la versión de la rúbrica participan en los archivos de bloqueo de traducción. Habilitar la evaluación, cambiar modelos o umbrales, o eliminar la evaluación hace que las traducciones anteriores se vuelvan obsoletas para la siguiente ejecución. Las claves del proveedor están excluidas de los bloquerfiles.

## El límite de revisión humana

La salida del modelo es trabajo propuesto, no una integración automática. La actividad de configuración y traducción permanece visible en Glossia, mientras los cambios del repositorio se publican a través de una solicitud de pull request para que el equipo la revise. Esto preserva el mismo límite de calidad y propiedad que los equipos ya usan para el código.
