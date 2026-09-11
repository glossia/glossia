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

- Renombrar el binario dentro de los archivos de lanzamiento desde un nombre específico de la plataforma a simplemente `glossia`.
- Quitar el atributo de cuarentena de macOS de los binarios antes del empaquetado.

## 0.14.0

*2026-02-14*

#### Características

- Agregar script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Haga que la configuración del proveedor de OAuth sea opcional en producción. La aplicación debe arrancar incluso sin credenciales de OAuth de GitHub/GitLab configuradas. Solo configure los proveedores cuando las variables de entorno estén presentes.
- Usar el puerto 4000 como predeterminado para producción y mantener 4050 para desarrollo. El proxy de producción espera que la aplicación esté en el puerto 4000. El `runtime.exs` predeterminado era 4050, lo que causó que las verificaciones de salud fallaran durante el despliegue.

#### Características

- Añadir aplicación Phoenix con inicio de sesión OAuth, mejoras de documentación y mejoras de la interfaz de usuario.
- Usar logo redondeado como favicon.
- Migrar CLI a Bun y actualizar las compilaciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Corrección de errores

- Evitar el desbordamiento horizontal de fragmentos de código en móviles.
- Añadir margen derecho adecuado a los fragmentos de código en móvil.
- Mejorar el diseño responsivo para móviles para evitar el desbordamiento horizontal.
- Aplicar el formato Biome.
- Añadir encabezados de grupo a la plantilla de notas de la versión.
- Actualizar el flujo de traducción de Bun a Rust.
- Alinear el cuerpo de la publicación con el diseño de héroe y mejorar el contenido de la entrada del blog.
- Centrar el contenido de la publicación del blog horizontalmente.
- Corregir el pánico al truncar resultados de herramientas UTF-8 de múltiples bytes.

#### Características

- Añadir herramientas de primera parte y la sección del sitio web.
- Mostrar los pasos de verificación de herramientas.
- Simplificar la salida del progreso.
- Colorear las líneas del progreso.
- Mostrar la actividad de traducción y validación.
- Dar formato a las líneas de herramientas.
- Hacer que el sitio web sea responsivo con menú móvil y diseño multi-punto de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añadir sección de Refinamiento progresivo a la página de inicio.
- Añadir sección de blog con soporte SEO y primera publicación.
- Unificar la salida CLI con formato de verbo alineado a la derecha.
- Colorear la salida CLI con un formato de mensajes más rico.
- Añadir imagen cuadrada OG y etiquetas meta de tarjeta de Twitter.
- Haga que el agente coordinador sea autónomo con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Agregue soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones

- Divida CI en tareas separadas de formato, verificación de tipos, pruebas y construcción.
- Reescriba la CLI desde TypeScript/Bun a Rust.