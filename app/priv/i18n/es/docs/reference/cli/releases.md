%{
  title: "Lanzamientos",
  summary: "Historial de liberaciones de la CLI.",
  category: "Referencia",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correcciones de errores

- Renombrar el binario en los archivos de lanzamiento desde el nombre específico de la plataforma a simplemente `glossia`.
- Eliminar el atributo xattr de cuarentena de macOS de los binarios antes del empaquetado.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Haga opcional la configuración del proveedor OAuth en producción. La aplicación debe arrancar incluso sin las credenciales OAuth de GitHub/GitLab configuradas. Solo configure los proveedores cuando las variables de entorno estén presentes.
- Use 4000 como puerto por defecto para producción y mantenga 4050 para el desarrollo. El proxy de producción espera que la aplicación esté en el puerto 4000. El `runtime.exs` valor por defecto era 4050, lo que provocó que las comprobaciones de salud fallaran durante el despliegue.

#### Características

- Añadir aplicación Phoenix con inicio de sesión OAuth, mejoras de documentación y mejoras de la interfaz de usuario.
- Usar logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las construcciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Corrección de errores

- Prevenir el desbordamiento horizontal de fragmentos de código en móvil.
- Añadir un margen derecho adecuado a los fragmentos de código en móviles.
- Mejorar el diseño adaptable móvil para evitar el desbordamiento horizontal.
- Aplicar el formato de biome.
- Añadir encabezados de grupo a la plantilla de notas de la versión.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo del artículo con el diseño héroe y mejorar el contenido del artículo del blog.
- Centrar horizontalmente el contenido del artículo del blog.
- Corregir el pánico al truncar los resultados de la herramienta UTF-8 de varios bytes.

#### Características

- Agregar herramientas de primera parte y sección del sitio web.
- Mostrar pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Dar tinte a las líneas de progreso.
- Mostrar actividad de traducción y validación.
- Formatear líneas de herramientas.
- Hacer el sitio web responsivo con menú móvil y diseño de múltiples puntos de corte.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo de CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añadir sección de Refinamiento progresivo a la página de inicio.
- Añadir sección de blog con soporte para SEO y la primera entrada del blog.
- Unificar salida de CLI con formato de verbo alineado a la derecha.
- Colorizar salida de CLI con un formato de mensajes más rico.
- Añadir imagen cuadrada OG y metaetiquetas de tarjeta de Twitter.
- Hacer que el agente coordinador sea agéntico con uso de herramientas.
- Reescribir `glossia init` con el Protocolo del Cliente de Agente (ACP).
- Agregar soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones

- Dividir CI en trabajos separados de formato, validación de tipos, pruebas y compilación.
- Reescribir CLI desde TypeScript/Bun a Rust.