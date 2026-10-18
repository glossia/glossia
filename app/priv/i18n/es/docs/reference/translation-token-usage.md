%{
  title: "Uso de tokens de traducción",
  summary:
    "Comprenda la contabilidad de tokens y los desgloses de proyecto, idioma y archivo fuente.",
  category: "referencia",
  section: "translation",
  order: 12
}
---

## Tablero de control

Abre **Ajustes → Modelos → Uso de tokens** para ver el uso informado por el proveedor para traducciones generativas. El acceso requiere permisos para leer la configuración del modelo.

El tablero de control admite los últimos 7, 30 o 90 días calendario, incluido hoy, en UTC. Los filtros de modelo, proyecto e idioma se aplican a los totales, el gráfico diario y el desglose. La búsqueda solo se aplica a las filas de desglose. El período seleccionado, la dimensión, los filtros, la búsqueda, el ordenamiento y la página se conservan en la URL.

## Métricas

| Métrica | Significado |
| --- | --- |
| Tokens de entrada | Entrada procesada por el proveedor, incluidas las lecturas de caché e inscripciones de caché informadas. |
| Tokens de salida | Salida informada por el proveedor, incluido el razonamiento cuando el proveedor lo incluye en su conteo de salida. |
| Tokens de entrada en caché | Lecturas de caché. Un subconjunto de tokens de entrada, no un cargo adicional en el total. |
| Tokens totales | Tokens de entrada más tokens de salida. |
| Respuestas | Respuestas con tanto conteo de entrada como de salida y un total de tokens positivo. Los retrocesos con uso ausente y cero se ignoran. |

Los contadores de tokens no son costos monetarios. Los proveedores pueden cobrar tarifas diferentes para entrada, salida, entrada almacenada en caché e inscripciones de caché.

Cada respuesta informada se cuenta, incluidos los reintentos de validación, los reintentos de corrección de calidad y las respuestas rechazadas por alcanzar su límite de salida. Los archivos omitidos y las coincidencias de punto de control que no invoquen a un modelo no generan uso. Las solicitudes fallidas sin uso no pueden ser contadas.

## Dimensiones

- **Proyectos** agrupan el uso por proyecto. Use el filtro de proyecto para restringir todas las métricas a un único proyecto.
- **Idiomas** agrupan por idioma objetivo, como `es` o `ja`, a través de los proyectos en el alcance actual.
- **Archivos** agrupan por ruta de origen y proyecto. El mismo archivo fuente traducido a múltiples idiomas aparece una vez; los archivos con el mismo nombre en diferentes proyectos permanecen separados.

**Sin asignar** mantiene visibles las solicitudes sin metadatos de proyecto o ruta de origen. Las traducciones de repositorios proporcionan ambos automáticamente. Las solicitudes de API de contenido único pueden proporcionar `project_id` y `source_path` para atribución; un ID de proyecto fuera de la cuenta autenticada se considera sin asignar. El metadato opcional inválido o sobredimensionado queda sin asignar sin descartar los conteos de tokens.

## Cobertura

El uso se recopila desde las respuestas de clave API y OAuth de ReqLLM, completaciones de Together y giros locales de Codex finalizados. Solo se persisten los conteos informados por el proveedor. Las sesiones locales de Pi y las evaluaciones de modelos de decisión no están incluidas. Las traducciones históricas no se rellenan ni estiman. Por lo tanto, los totales describen el uso registrado, no una factura completa del proveedor.

El libro de registros almacena la cuenta, el proyecto, el identificador y el manipulador, el idioma objetivo, la ruta de origen, los conteos y la hora. No almacena prompts, contenido traducido, credenciales o respuestas crudas del proveedor. Los fallos de registro de uso se registran sin interrumpir la traducción.
