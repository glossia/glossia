%{
  title: "Lanzamientos",
  summary: "Historial de lanzamientos de CLI.",
  category: "Referencia",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Corrección de errores

- Renombrar el binario dentro de los archivos de lanzamiento desde el nombre específico de la plataforma a simplemente `glossia`.
- Quitar el atributo de cuarentena xattr de los binarios antes del empaquetado.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Haga que la configuración del proveedor OAuth sea opcional en producción. La aplicación debe iniciar incluso sin establecer las credenciales OAuth de GitHub/GitLab. Configure los proveedores solo cuando las variables de entorno estén presentes.
- Utilice el puerto 4000 por defecto para producción y mantenga 4050 para desarrollo. El proxy de producción espera que la aplicación esté en el puerto 4000. El `runtime.exs` por defecto era 4050, lo que provocó que las comprobaciones de salud fallaran durante el despliegue.

#### Características

- Añadir aplicación Phoenix con inicio de sesión OAuth, mejoras de documentación y mejoras de la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las construcciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de fragmentos de código en dispositivos móviles.
- Añade el margen derecho apropiado a los fragmentos de código en móviles.
- Mejora la disposición adaptable móvil para evitar el desbordamiento horizontal.
- Aplica el formateo biome.
- Añade encabezados de grupo a la plantilla de notas de lanzamiento.
- Actualiza el flujo de trabajo de traducción desde Bun a Rust.
- Alinea el cuerpo de la publicación con la disposición hero y mejora el contenido de las publicaciones del blog.
- Centra el contenido de la publicación del blog horizontalmente.
- Corrige el pánico al acortar los resultados de la herramienta UTF-8 de varios bytes.

#### Características

- Añade herramientas de primera parte y sección de sitio web.
- Muestra los pasos de verificación de herramientas.
- Simplifica la salida de progreso.
- Colorea las líneas de progreso.
- Muestra la actividad de traducción y validación.
- Formatea las líneas de herramientas.
- Haz que el sitio web sea responsivo con menú móvil y diseño de múltiples puntos de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir verificación de formato con Biome.
- Añadir sección de Refinamiento Progresivo a la página de inicio.
- Añadir sección de blog con soporte SEO y primera entrada del blog.
- Unificar la salida del CLI con formato de verbos alineados a la derecha.
- Colorizar la salida del CLI con un formato de mensajes más rico.
- Añadir imagen cuadrada OG y etiquetas meta de tarjetas de Twitter.
- Hacer que el agente coordinador sea agéntico con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añadir soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones

- Separar CI en trabajos independientes de formato, verificación de tipos, pruebas y compilación.
- Reescribir CLI desde TypeScript/Bun a Rust.