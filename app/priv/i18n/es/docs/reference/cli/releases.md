%{
  title: "Versiones",
  summary: "Historial de versiones CLI.",
  category: "Referencia",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Correcciones de errores
- Renombrar el binario dentro de los archivos de lanzamiento desde el nombre específico de plataforma a simplemente `glossia`.
- Eliminar la atribución de extensión de cuarentena de macOS de los binarios antes del empaquetado.

## 0.14.0

*2026-02-14*

#### Características
- Agregar un script de lanzamiento local y un flujo de trabajo de changelog mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores
- Corregir el manejo de configuración del proveedor de inicio de sesión alojado.
- Corregir las verificaciones de salud del servicio alojado.

#### Características
- Agregar aplicación Phoenix con inicio de sesión OAuth, mejoras para documentación y mejoras de interfaz de usuario.
- Usar el logo redondeado como icono de página.
- Migrar CLI a Bun y actualizar las construcciones de ejecución de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores
- Evitar el desbordamiento horizontal de fragmentos de código en móvil.
- Agregar el margen derecho adecuado para los fragmentos de código en móvil.
- Mejorar el diseño adaptable para móviles para evitar el desbordamiento horizontal.
- Aplicar formato de biome.
- Agregar encabezados de grupo a la plantilla de notas de lanzamiento.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo del post con el diseño del héroe y mejorar el contenido del post del blog.
- Centrar el contenido del post del blog horizontalmente.
- Corregir el pánico al truncar resultados de herramientas Unicode UTF-8 de múltiples bytes.

#### Características
- Agregar sección de herramientas de primera parte y sitio web.
- Mostrar los pasos de verificación de herramienta.
- Simplificar la salida de progreso.
- Teñir las líneas de progreso.
- Mostrar las actividades de traducción y validación.
- Formatear las líneas de herramienta.
- Hacer el sitio web adaptable con menú móvil y diseño de múltiples puntos de ruptura.
- Reimplementar CLI en Bun/TypeScript.
- Agregar flujo de trabajo de CI y pruebas.
- Agregar verificación de formato con Biome.
- Agregar sección de Refinamiento Progresivo en la página principal.
- Agregar sección de blog con soporte SEO y primer post del blog.
- Unificar la salida de CLI con formato de verbo alineado a la derecha.
- Colorizar la salida de CLI con formato de mensaje más rico.
- Agregar imagen cuadrada OG y metaetiquetas de tarjeta de Twitter.
- Hacer coordinador agente agéntico con uso de herramienta.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Agregar soporte de Gemini, validación automática, seguimiento de tokens y mejora de fiabilidad.

#### Refactorizaciones
- Dividir CI en tareas separadas de formato, verificación de tipos, prueba y compilación.
- Reescribir CLI desde TypeScript/Bun a Rust.
