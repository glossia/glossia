%{
  title: "Uso de tokens de traducción",
  summary:
    "Comprender la contabilidad de tokens y los desgloses de proyecto, idioma y archivo fuente.",
  category: "referencia",
  section: "translation",
  order: 12
}
---
## Panel de control

Abrir **Configuración → Modelos → Uso de tokens** para ver el uso reportado por el proveedor de traducciones generativas. El acceso requiere permiso para leer la configuración del modelo.

El panel de control admite los últimos 7, 30 o 90 días calendario, incluido hoy, en UTC. Los filtros de modelo, proyecto e idioma se aplican a los totales, el gráfico diario y el desglose. La búsqueda solo se aplica a las filas de desglose. El período seleccionado, la dimensión, los filtros, la búsqueda, el ordenamiento y la página se conservan en la URL.

## Métricas

| Métrica | Significado |
| --- | --- |
| Tokens de entrada | Entrada procesada por el proveedor, incluidas las lecturas de caché y las escrituras de caché reportadas. |
| Tokens de salida | Salida reportada por el proveedor, incluido el razonamiento cuando el proveedor lo incluye en su conteo de salida. |
| Tokens de entrada en caché | Lecturas de caché. Un subconjunto de los tokens de entrada, no un cargo adicional en el total. |
| Tokens totales | Tokens de entrada más tokens de salida. |
| Respuestas | Respuestas con conteos de entrada y salida y un total de tokens positivo. Los sustitutos de uso ausente con valor cero se ignoran. |

Los conteos de token no son costos monetarios. Los proveedores pueden aplicar tarifas diferentes para la entrada, la salida, la entrada en caché y las escrituras de caché.

Cada respuesta reportada se cuenta, incluidos los reintentos de validación, los reintentos de corrección de calidad y las respuestas rechazadas por alcanzar su límite de salida. Los archivos omitidos y los puntos de control que no invocan un modelo no acumulan uso. No se pueden contar las solicitudes fallidas sin uso.

## Dimensiones

- **Proyectos** agrupa el uso por proyecto. Usa el filtro de proyecto para limitar todas las métricas a un solo proyecto.
- **Idiomas** agrupa por localización objetivo, como `es` o `ja`, en todos los proyectos del alcance actual.
- **Archivos** agrupa por ruta de origen y proyecto. El mismo archivo de origen traducido a múltiples idiomas aparece una vez; los archivos con el mismo nombre en proyectos distintos permanecen separados.

**Sin asignar** mantiene las solicitudes sin metadatos de proyecto o source-path visibles. Las traducciones del repositorio proveen ambos automáticamente. Las solicitudes de API de contenido único pueden proporcionar `project_id` y `source_path` para atribución; un ID de proyecto fuera de la cuenta autenticada se trata como sin asignar. Los metadatos opcionales inválidos o excesivos se asignan como sin asignar sin descartar los conteos de tokens.

## Cobertura

El uso se recopila a partir de las respuestas de API-key de ReqLLM y OAuth, las terminaciones de Together y los turnos locales de Codex completados. Solo se persisten los contadores reportados por el proveedor. Las sesiones locales Pi y las evaluaciones de modelos de decisión no están incluidas. Las traducciones históricas no se rellenan ni se estiman. Por lo tanto, los totales describen el uso registrado, no una factura completa del proveedor.

El registro almacena la cuenta, el proyecto, el identificador de modelo y handle, el idioma de destino, la ruta de origen, los conteos y la marca de tiempo. No almacena prompts, contenido traducido, credenciales o respuestas crudas del proveedor. Los fallos en el registro de uso se inscriben sin interrumpir la traducción.