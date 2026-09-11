%{
  title: "Lanzamientos",
  summary: "Historial de versiones de la CLI.",
  category: "referencia",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correcciones de errores

- Renombrar el binario en los archivos de versión desde el nombre específico de la plataforma a simplemente `glossia`.
- Eliminar el xattr de cuarentena de macOS de los binarios antes de empaquetar.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de trabajo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Hacer la configuración del proveedor OAuth opcional en producción. La aplicación debe iniciar incluso sin credenciales OAuth de GitHub/GitLab configuradas. Solo configurar proveedores cuando las variables de entorno estén presentes.
- Por defecto, usar el puerto 4000 para producción y mantener 4050 para desarrollo. El proxy de producción espera que la aplicación esté en el puerto 4000. El `runtime.exs` por defecto era 4050, lo que hizo que las comprobaciones de salud fallaran durante el despliegue.

#### Características

- Añadir aplicación Phoenix con inicio de sesión OAuth, mejoras de la documentación y mejoras de la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las construcciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Corrección de errores

- Evitar el desbordamiento horizontal de los fragmentos de código en móviles.
- Añadir un margen derecho adecuado a los fragmentos de código en móvil.
- Mejorar la maquetación responsive móvil para evitar el desbordamiento horizontal.
- Aplicar formato Biome.
- Añadir encabezados de grupo a la plantilla de notas de lanzamiento.
- Actualizar el flujo de trabajo de traducción de Bun a Rust.
- Alinear el cuerpo de la entrada con el diseño hero y mejorar el contenido de la entrada del blog.
- Centrar el contenido de la entrada del blog horizontalmente.
- Corregir pánico al truncar resultados de herramientas multi-byte UTF-8.

#### Características

- Añadir sección de herramientas de primera parte y del sitio web.
- Mostrar pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Colorear líneas de progreso.
- Mostrar actividad de traducción y validación.
- Formatear líneas de herramientas.
- Hacer el sitio web adaptable con menú móvil y diseño de múltiples puntos de quiebre.
- Reimplementar la CLI en Bun/TypeScript.
- Añadir flujo de trabajo CI y pruebas.
- Añadir comprobación de formato con Biome.
- Añadir sección de Refinamiento Progresivo a la página de inicio.
- Añadir sección de blog con soporte SEO y primera entrada.
- Unificar la salida de la CLI con formato de verbo alineado a la derecha.
- Colorizar la salida de la CLI con un formato de mensajes más rico.
- Añadir imagen OG cuadrada y etiquetas meta de tarjeta de Twitter.
- Hacer que el agente coordinador sea agéntico con uso de herramientas.
- Reescribir `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Añadir soporte para Gemini, validación automática, seguimiento de tokens y mejoras en la fiabilidad.

#### Refactorizaciones

- Separar CI en trabajos independientes de formato, verificación de tipos, pruebas y compilación.
- Reescribir CLI desde TypeScript/Bun a Rust.