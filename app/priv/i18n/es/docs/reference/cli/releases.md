%{
  title: "Lanzamientos",
  summary: "Historial de lanzamientos de la CLI.",
  category: "Referencia",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correcciones de errores

- Renombrar binario dentro de los archivos de lanzamiento de nombre específico de la plataforma a simplemente `glossia`.
- Eliminar el atributo xattr de cuarentena de macOS de los binarios antes del empaquetado.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de trabajo del registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones

- Corregir la gestión de la configuración del proveedor de inicio de sesión alojado.
- Corregir las comprobaciones de salud del servicio alojado.

#### Características

- Añadir aplicación Phoenix con inicio de sesión OAuth, mejoras en la documentación y mejoras en la interfaz de usuario.
- Usar logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las compilaciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de los fragmentos de código en móviles.
- Añadir margen derecho adecuado a los fragmentos de código en móviles.
- Mejorar la disposición responsiva móvil para prevenir el desbordamiento horizontal.
- Aplicar formato de biome.
- Añadir encabezados de grupo a la plantilla de notas de lanzamiento.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo de la entrada con el diseño héroe y mejorar el contenido de la publicación de blog.
- Centrar el contenido de la publicación de blog horizontalmente.
- Corregir el pánico al truncar resultados de herramientas de múltiples bytes UTF-8.

#### Características

- Añadir sección de herramientas y sitio web de primera parte.
- Mostrar pasos de verificación de herramientas.
- Simplificar la salida del progreso.
- Dar color a las líneas de progreso.
- Mostrar actividad de traducción y validación.
- Dar formato a las líneas de herramientas.
- Hacer sitio web responsivo con menú móvil y diseño multi-punto de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añade el flujo de trabajo CI y las pruebas.
- Añade la verificación de formato con Biome.
- Añade la sección de Refinamiento Progresivo a la página principal.
- Añade la sección de blog con soporte de SEO y la primera publicación.
- Unifica la salida de CLI con formato de verbos alineados a la derecha.
- Coloriza la salida de CLI con un formateo de mensajes más enriquecido.
- Añade la imagen OG cuadrada y las etiquetas de tarjeta de Twitter.
- Haz que el agente coordinador sea agéntico con uso de herramientas.
- Reescritura `glossia init` con el Protocolo de Cliente del Agente (ACP).
- Añadir soporte para Gemini, validación automática, seguimiento de tokens y mejoras en la fiabilidad.

#### Refactorizaciones

- Dividir CI en trabajos separados de formato, verificación de tipos, pruebas y construcción.
- Reescritura CLI desde TypeScript/Bun a Rust.