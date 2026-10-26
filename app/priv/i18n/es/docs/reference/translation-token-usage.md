%{
  title: "Uso de tokens de traducción",
  summary:
    "Comprende la contabilidad de tokens y los desgloses de proyecto, idioma y archivo de fuente.",
  category: "Referencia",
  section: "translation",
  order: 12
}
---

## Panel

Abre **Configuración → Modelos → Uso de tokens** para ver el uso reportado por el proveedor para las traducciones generativas. Se requiere permiso para leer la configuración del modelo.

El panel de control admite los últimos 7, 30 o 90 días calendario, incluido el de hoy, en UTC. Los filtros de modelo, proyecto y idioma se aplican a los totales, el gráfico diario y el desglose. La búsqueda solo se aplica a las filas de desglose. El periodo seleccionado, la dimensión, los filtros, la búsqueda, el ordenamiento y la página se conservan en la URL.

## Métricas

| Métrica | Significado |
| --- | --- |
| Tokens de entrada | Entrada procesada por el proveedor, incluidas las lecturas y escrituras de caché reportadas. |
| Tokens de salida | Salida reportada por el proveedor, incluido el razonamiento cuando el proveedor lo incluye en su conteo de salida. |
| Tokens de entrada en caché | Lecturas de caché. Un subconjunto de los tokens de entrada, no un recargo adicional en el total. |
| Tokens totales | Tokens de entrada más tokens de salida. |
| Respuestas | Respuestas con conteos tanto de entrada como de salida y un total de tokens positivo. Se ignoran los registros de uso ausente con valor cero. |

Los conteos de tokens no son costos monetarios. Los proveedores pueden cobrar tarifas diferentes para la entrada, la salida, la entrada en caché y las escrituras de caché.

Cada respuesta reportada se cuenta, incluidos los reintentos de validación, los reintentos de corrección de calidad y las respuestas rechazadas por alcanzar su límite de salida. Los archivos omitidos y los registros de checkpoint que no llaman a un modelo no agregan ningún uso. No se pueden contar las solicitudes fallidas sin uso.

## Dimensiones

- **Proyectos** agrupa el uso por proyecto. Utilice el filtro de proyecto para limitar todas las métricas a un solo proyecto.
- **Idiomas** agrupa por localización de destino, como `es` o `ja`, en todos los proyectos dentro del alcance actual.
- **Archivos** agrupa por ruta de origen y proyecto. El mismo archivo fuente traducido en múltiples idiomas aparece una vez; los archivos con el mismo nombre en diferentes proyectos permanecen separados.

**No asignado** mantiene visibles las solicitudes sin metadatos de proyecto o ruta de origen. Las traducciones del repositorio proporcionan ambos automáticamente. Las solicitudes de API de contenido único pueden proporcionar `project_id` y `source_path` para atribución; un ID de proyecto fuera de la cuenta autenticada se trata como no asignado. Los metadatos opcionales inválidos o excesivos se asignan como no asignados sin descartar los conteos de tokens.

## Cobertura

El uso se recopila desde las respuestas de las claves API de ReqLLM y OAuth, las terminaciones de Together y las vueltas locales de Codex completadas. Solo los conteos reportados por el proveedor se conservan. Las sesiones locales Pi y las evaluaciones del modelo de decisión no se incluyen. Las traducciones históricas no se rellenan ni se estiman. Por lo tanto, los totales describen el uso registrado, no una factura completa del proveedor.

El libro maestro almacena cuenta, proyecto, identificador y manejador del modelo, localización de destino, ruta de origen, conteos y marca de tiempo. No almacena indicaciones, contenido traducido, credenciales o respuestas crudas del proveedor. Los errores de registro de uso se registran sin interrumpir la traducción.
