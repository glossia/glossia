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

- Renombrar el binario dentro de los archivos de lanzamiento desde nombre específico de plataforma a simplemente `glossia`.
- Eliminar el atributo xattr de cuarentena de macOS de los binarios antes de empaquetar.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de liberación local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Hacer que la configuración del proveedor OAuth sea opcional en producción. La aplicación debe arrancar incluso sin credenciales OAuth de GitHub/GitLab configuradas. Configura los proveedores solo cuando las variables de entorno estén presentes.
- Usa el puerto 4000 por defecto para producción y mantén 4050 para desarrollo. El proxy de producción espera la aplicación en el puerto 4000. El `runtime.exs` el valor predeterminado era 4050, lo que provocó que las comprobaciones de salud fallaran durante el despliegue.

#### Características

- Añadir la aplicación de Phoenix con inicio de sesión OAuth, mejoras de la documentación y de la interfaz de usuario.
- Usar el logotipo redondeado como icono de pestaña.
- Migrar el CLI a Bun y actualizar las construcciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de fragmentos de código en móviles.
- Añadir un margen derecho adecuado a los fragmentos de código en móviles.
- Mejorar el diseño responsivo móvil para evitar el desbordamiento horizontal.
- Aplicar formato biome.
- Añadir encabezados de grupo a la plantilla de notas de versión.
- Actualizar el flujo de trabajo de traducción desde Bun a Rust.
- Alinear el cuerpo de la publicación con el diseño héroe y mejorar el contenido de la publicación del blog.
- Centrar el contenido de la publicación del blog horizontalmente.
- Corregir el pánico al truncar los resultados de la herramienta UTF-8 de varios bytes.

#### Características

- Añadir herramientas de primera parte y la sección del sitio web.
- Mostrar los pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Colorizar las líneas de progreso.
- Mostrar la actividad de traducción y validación.
- Dar formato a las líneas de herramientas.
- Hacer el sitio web responsivo con menú móvil y diseño multi-punto de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir verificación de formato con Biome.
- Añadir sección de Refinamiento progresivo a la página principal.
- Añadir sección de blog con soporte SEO y primera entrada del blog.
- Unificar salida CLI con formato de verbo alineado a la derecha.
- Colorear salida CLI con formato de mensaje más rico.
- Añadir imagen cuadrada OG y etiquetas meta de tarjetas de Twitter.
- Hacer que el agente coordinador sea agéntico con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Agregar soporte para Gemini, validación automática, seguimiento de tokens y mejoras de confiabilidad.

#### Refactorizaciones

- Dividir CI en trabajos separados de formato, verificación de tipos, pruebas y construcción.
- Reescribir la CLI desde TypeScript/Bun a Rust.