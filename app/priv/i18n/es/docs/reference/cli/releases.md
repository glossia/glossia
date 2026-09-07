%{
  title: "Lanzamientos",
  summary: "Historial de lanzamientos CLI.",
  category: "Referencia",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correcciones de errores

- Renombrar el binario dentro de los archivos de liberación del nombre específico de la plataforma a simplemente `glossia`glossia
- Quitar el atributo de cuarentena de macOS de los binarios antes de empaquetar.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de liberación local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Haz que la configuración del proveedor de OAuth sea opcional en producción. La aplicación debería arrancar incluso sin credenciales de OAuth de GitHub/GitLab configuradas. Configura solo los proveedores cuando las variables de entorno estén presentes.
- Usa el puerto 4000 por defecto para producción y mantén 4050 para desarrollo. El proxy de producción espera la aplicación en el puerto 4000. El `runtime.exs`runtime.exs

#### Características

- Añadir una aplicación Phoenix con inicio de sesión OAuth, mejoras para la documentación y mejoras de interfaz de usuario.
- Usa el logo redondeado como favicon.
- Migra el CLI a Bun y actualiza los ejecutables de la integración continua.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de fragmentos de código en dispositivos móviles.
- Añade el margen derecho adecuado a los fragmentos de código en dispositivos móviles.
- Mejora el diseño responsivo móvil para evitar el desbordamiento horizontal.
- Aplica el formato Biome.
- Añade encabezados de grupo para la plantilla de notas de liberación.
- Actualiza el flujo de trabajo de traducción desde Bun hasta Rust.
- Alinea el cuerpo de la publicación con el diseño del héroe y mejora el contenido de la publicación del blog.
- Centra el contenido de la publicación horizontalmente.
- Corrige el pánico al recortar resultados de herramientas de múltiples bytes UTF-8.

#### Características

- Añadir la sección de herramientas y del sitio web de primera parte.
- Exponer los pasos de verificación de la herramienta.
- Simplifica la salida de progreso.
- Tinte las líneas de progreso.
- Muestra la actividad de traducción y validación.
- Formatea las líneas de la herramienta.
- Haz que la web sea responsiva con menú móvil y diseño de varios puntos de ruptura.
- Reimplementar el CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añade la sección de Refinamiento Progresivo a la página de inicio.
- Añade la sección de blog con soporte SEO y la primera publicación del blog.
- Unifica la salida CLI con formato de verbo alineado a la derecha.
- Coloriza la salida CLI con un formato de mensaje más rico.
- Añade la imagen OG cuadrada y las etiquetas meta de tarjeta Twitter.
- Haz que el agente coordinador sea autónomo con el uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añade soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones

- Divide la CI en tareas de formato, verificación de tipos, pruebas y construcción separadas.
- Reescribir el CLI desde TypeScript/Bun a Rust.