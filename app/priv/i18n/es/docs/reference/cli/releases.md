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

- Renombrar el binario dentro de los archivos de lanzamiento desde el nombre específico de plataforma a solo `glossia`.
- Eliminar el atributo xattr de cuarentena de macOS de los binarios antes de empaquetarlos.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Hacer que la configuración del proveedor OAuth sea opcional en producción. La aplicación debería arrancar incluso sin credenciales OAuth de GitHub/GitLab configuradas. Configurar los proveedores solo cuando estén presentes las variables de entorno.
- Usar el puerto 4000 por defecto para producción y mantener 4050 para desarrollo. El proxy de producción espera que la aplicación esté en el puerto 4000. El `runtime.exs` por defecto era 4050, lo que causó que las comprobaciones de salud fallaran durante el despliegue.

#### Características

- Añadir una aplicación de Phoenix con inicio de sesión OAuth, mejoras en la documentación y en la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las construcciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de los fragmentos de código en móviles.
- Añadir margen derecho adecuado a los fragmentos de código en móviles.
- Mejorar el diseño responsivo móvil para evitar el desbordamiento horizontal.
- Aplicar formato con biome.
- Añadir encabezados de grupo a la plantilla de notas de lanzamiento.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo de la publicación con el diseño del héroe y mejorar el contenido de la entrada del blog.
- Centrar el contenido de la publicación del blog horizontalmente.
- Corregir el pánico al truncar resultados de herramientas con múltiples bytes UTF-8.

#### Características

- Añadir sección de herramientas de primera parte y de sitio web.
- Mostrar pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Colorar las líneas de progreso.
- Mostrar actividad de traducción y validación.
- Formatar líneas de herramientas.
- Hacer sitio web responsivo con menú móvil y diseño multi-punto de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añadir sección de refinamiento progresivo a la página de inicio.
- Añadir sección de blog con soporte SEO y primera publicación de blog.
- Unificar la salida de CLI con formato de verbos alineados a la derecha.
- Colorear la salida de CLI con formato de mensajes más rico.
- Añadir imagen cuadrada OG y etiquetas meta de tarjeta de Twitter.
- Hacer que el agente coordinador sea autónomo con uso de herramientas.
- Reescribir `glossia init` con Protocolo de Cliente de Agente (ACP).
- Añadir soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorizaciones

- Dividir CI en trabajos separados de formato, verificación de tipos, pruebas y compilación.
- Reescribir la CLI desde TypeScript/Bun a Rust.