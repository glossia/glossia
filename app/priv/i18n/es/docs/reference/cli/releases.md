%{
  title: "Versiones",
  summary: "Historial de versiones de la CLI.",
  category: "reference",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correcciones de errores
- Cambiar el nombre del binario dentro de los archivos de publicación, del nombre específico de la plataforma a simplemente `glossia`.
- Eliminar el atributo extendido de cuarentena de macOS de los binarios antes de empaquetarlos.

## 0.14.0

*2026-02-14*

#### Funcionalidades
- Añadir un script local de publicación y un flujo de trabajo para mantener manualmente el registro de cambios.

## 0.2.0

*2026-02-14*

#### Correcciones de errores
- Hacer opcional la configuración de proveedores OAuth en producción. La aplicación debe iniciarse aunque no se hayan establecido las credenciales OAuth de GitHub/GitLab. Configurar los proveedores únicamente cuando estén presentes las variables de entorno.
- Usar el puerto 4000 de forma predeterminada en producción y mantener el 4050 en desarrollo. El proxy de producción espera que la aplicación esté en el puerto 4000. El valor predeterminado de `runtime.exs` era 4050, lo que provocaba fallos en las comprobaciones de estado durante el despliegue.

#### Funcionalidades
- Añadir una aplicación Phoenix con inicio de sesión mediante OAuth, mejoras en la documentación y mejoras en la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar la interfaz de línea de comandos a Bun y actualizar las compilaciones de ejecutables de integración continua.

## 0.1.0

*2026-02-12*

#### Correcciones de errores
- Evitar el desbordamiento horizontal de los fragmentos de código en dispositivos móviles.
- Añadir un margen derecho adecuado a los fragmentos de código en dispositivos móviles.
- Mejorar el diseño adaptable para dispositivos móviles a fin de evitar el desbordamiento horizontal.
- Aplicar el formato de Biome.
- Añadir encabezados de grupo a la plantilla de notas de la versión.
- Migrar el flujo de traducción de Bun a Rust.
- Alinear el cuerpo de la publicación con el diseño de la cabecera principal y mejorar el contenido de la publicación del blog.
- Centrar horizontalmente el contenido de las publicaciones del blog.
- Corregir el fallo crítico al truncar resultados de herramientas con caracteres UTF-8 multibyte.

#### Funcionalidades
- Añadir herramientas propias y una sección para el sitio web.
- Mostrar los pasos de verificación de las herramientas.
- Simplificar la salida de progreso.
- Colorear las líneas de progreso.
- Mostrar la actividad de traducción y validación.
- Dar formato a las líneas de las herramientas.
- Hacer que el sitio web sea adaptable, con un menú móvil y un diseño con varios puntos de ruptura.
- Volver a implementar la interfaz de línea de comandos en Bun/TypeScript.
- Añadir un flujo de integración continua y pruebas.
- Añadir comprobaciones de formato con Biome.
- Añadir la sección de Refinamiento progresivo a la página de inicio.
- Añadir una sección de blog compatible con la optimización para motores de búsqueda y la primera publicación del blog.
- Unificar la salida de la interfaz de línea de comandos con un formato de verbos alineados a la derecha.
- Colorear la salida de la interfaz de línea de comandos con un formato de mensajes más completo.
- Añadir una imagen cuadrada de Open Graph y etiquetas meta para tarjetas de Twitter.
- Convertir el agente coordinador en un agente autónomo con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añadir compatibilidad con Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones
- Dividir la integración continua en tareas independientes de formato, comprobación de tipos, pruebas y compilación.
- Reescribir la interfaz de línea de comandos de TypeScript/Bun a Rust.