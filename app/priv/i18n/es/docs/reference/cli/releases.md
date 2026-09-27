%{
  title: "Lanzamientos",
  summary: "Historial de lanzamientos de CLI.",
  category: "Referencia",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correcciones de errores

- Renombrar el binario dentro de los archivos de lanzamiento desde un nombre específico de la plataforma a solo `glossia`.
- Eliminar el xattr de cuarentena de macOS de los binarios antes de empaquetarlos.

## 0.14.0

*2026-02-14*

#### Funcionalidades

- Añadir script de lanzamiento local y flujo de trabajo de changelog mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Configuración del proveedor OAuth opcional en producción. La aplicación debería arrancar incluso sin credenciales OAuth de GitHub/GitLab configuradas. Solo configure los proveedores cuando las variables de entorno estén presentes.
- Default to port 4000 for production and keep 4050 for development. The production proxy expects the app on port 4000. The `runtime.exs` default was 4050, which caused health checks to fail during deployment.

#### Características

- Añadir una aplicación Phoenix con inicio de sesión OAuth, mejoras de la documentación y mejoras de la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las compilaciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de los fragmentos de código en móviles.
- Añadir un margen derecho adecuado a los fragmentos de código en dispositivos móviles.
- Mejorar la disposición adaptable móvil para evitar el desbordamiento horizontal.
- Aplicar el formato de biome.
- Añadir encabezados de grupo a la plantilla de notas de lanzamiento.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo de la publicación con la disposición de héroe y mejorar el contenido de la publicación del blog.
- Centrar horizontalmente el contenido de la publicación del blog.
- Corregir el pánico al truncar los resultados de las herramientas UTF-8 de varios bytes.

#### Características

- Añadir herramientas de primera parte y sección del sitio web.
- Mostrar pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Colorear las líneas de progreso.
- Mostrar la actividad de traducción y validación.
- Formatear líneas de herramientas.
- Hacer que el sitio web sea responsivo con menú móvil y diseño de múltiples puntos de ruptura.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añadir sección de Refinamiento progresivo a la página principal.
- Añadir sección de blog con soporte SEO y primer artículo del blog.
- Unificar la salida del CLI con formato de verbo alineado a la derecha.
- Colorizar la salida del CLI con un formato de mensajes más rico.
- Añadir imagen cuadrada OG y etiquetas meta de tarjetas de Twitter.
- Hacer al agente coordinador agéntico con uso de herramientas.
- Reescritura `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añadir soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorización

- Dividir CI en trabajos separados de formato, comprobación de tipos, pruebas y construcción.
- Reescribir la CLI desde TypeScript/Bun a Rust.