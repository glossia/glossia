%{
  title: "Lanzamientos",
  summary: "Historial de lanzamientos de CLI.",
  category: "referencia",
  subcategory: "CLI",
  order: 2
}
---

## 0.14.1

*2026-02-14*

#### Correcciones de errores
- Cambiar el nombre del binario dentro de los archivos de distribución desde su nombre específico de plataforma a simplemente `glossia`.
- Eliminar la atribución de cuarentena de macOS de los binarios antes de empaquetarlos.

## 0.14.0

*2026-02-14*

#### Características
- Añadir script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores
- Corregir el manejo de configuración del proveedor de inicio de sesión alojado.
- Corregir los controles de salud del servicio alojado.

#### Características
- Añadir aplicación Phoenix con inicio de sesión OAuth, mejoras en la documentación y mejoras en la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las compilaciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores
- Prevenir el desbordamiento horizontal de fragmentos de código en móviles.
- Añadir margen derecho adecuado a fragmentos de código en móviles.
- Mejorar el diseño adaptable para móviles para prevenir el desbordamiento horizontal.
- Aplicar el formateo de Biome.
- Añadir títulos de grupo a la plantilla de notas de lanzamiento.
- Actualizar el flujo de trabajo de traducción desde Bun a Rust.
- Alinear el contenido del artículo con el diseño hero y mejorar el contenido de la entrada del blog.
- Centrar el contenido de la entrada del blog horizontalmente.
- Corregir el pánico al truncar resultados multibyte UTF-8 de herramientas.

#### Características
- Añadir herramientas de primera parte y sección de sitio web.
- Mostrar los pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Colorar las líneas de progreso.
- Mostrar actividad de traducción y validación.
- Formatear las líneas de la herramienta.
- Hacer el sitio web responsive con menú móvil y diseño de múltiples puntos de ruptura.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo de CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añadir sección de Refinamiento Progresivo a la página principal.
- Añadir sección de blog con soporte SEO y primera entrada del blog.
- Unificar la salida de CLI con formato de verbo alineado a la derecha.
- Colorar la salida de CLI con un formato de mensaje más rico.
- Añadir imagen cuadrada OG y etiquetas meta de tarjeta de twitter.
- Hacer el agente coordinador autónomo con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añadir soporte de Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones
- Dividir CI en trabajos separados de formato, verificación de tipos, pruebas y compilación.
- Reescribir CLI desde TypeScript/Bun a Rust.
