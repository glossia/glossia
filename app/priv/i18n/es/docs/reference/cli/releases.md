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

- Renombrar binario dentro de los archivos de lanzamiento desde el nombre específico de la plataforma a simplemente `glossia`.
- Quitar el atributo de cuarentena xattr de macOS de los binarios antes de empaquetar.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Hacer la configuración del proveedor OAuth opcional en producción. La aplicación debe arrancar incluso sin credenciales OAuth de GitHub/GitLab configuradas. Solo configure los proveedores cuando las variables de entorno estén presentes.
- Usar el puerto 4000 por defecto para producción y mantener 4050 para desarrollo. El proxy de producción espera la aplicación en el puerto 4000. El `runtime.exs` por defecto era 4050, lo que provocó que las comprobaciones de estado fallaran durante el despliegue.

#### Características

- Añadir la aplicación Phoenix con inicio de sesión OAuth, mejoras de documentación y de la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las builds ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de los fragmentos de código en dispositivos móviles.
- Añadir un margen derecho adecuado a los fragmentos de código en móviles.
- Mejorar el diseño responsivo móvil para evitar el desbordamiento horizontal.
- Aplicar formato biome.
- Añadir encabezados de grupo a la plantilla de notas de versión.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo de la publicación con el layout de héroe y mejorar el contenido de la publicación del blog.
- Centrar el contenido de la publicación del blog horizontalmente.
- Corregir el pánico al truncar los resultados de herramientas UTF-8 de múltiples bytes.

#### Características

- Añadir herramientas de primera parte y sección web.
- Mostrar los pasos de verificación de la herramienta.
- Simplificar la salida de progreso.
- Colorear las líneas de progreso.
- Mostrar la actividad de traducción y validación.
- Formatear líneas de herramienta.
- Hacer el sitio web responsivo con menú móvil y diseño con múltiples puntos de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir verificación de formato con Biome.
- Añadir sección de Refinamiento Progresivo a la página de inicio.
- Añadir sección de blog con soporte SEO y primera entrada del blog.
- Unificar la salida CLI con formato de verbo alineado a la derecha.
- Colorizar la salida CLI con un formato de mensajes más rico.
- Añadir imagen cuadrada de OG y etiquetas meta de tarjeta de Twitter.
- Hacer al agente coordinador agéntico con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añadir soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorización

- Dividir CI en trabajos separados de formato, verificación de tipos, pruebas y construcción.
- Reescribir la CLI desde TypeScript/Bun a Rust.