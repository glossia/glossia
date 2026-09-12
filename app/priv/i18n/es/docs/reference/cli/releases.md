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

#### Correcciones

- Renombrar el binario dentro de los archivos de lanzamiento desde el nombre específico de la plataforma a simplemente `glossia`.
- Eliminar el xattr de cuarentena de macOS de los binarios antes de empaquetar.

## 0.14.0

*2026-02-14*

#### Características

- Añadir script de lanzamiento local y flujo de registro de cambios mantenido manualmente.

## 0.2.0

*2026-02-14*

#### Correcciones de errores

- Hacer opcional la configuración del proveedor de OAuth en producción. La aplicación debe arrancar incluso sin credenciales OAuth de GitHub/GitLab configuradas. Configurar los proveedores únicamente cuando estén presentes las variables de entorno.
- Usar el puerto 4000 por defecto en producción y mantener 4050 en desarrollo. El proxy de producción espera la aplicación en el puerto 4000. El `runtime.exs` predeterminado era 4050, lo que provocó que las comprobaciones de salud fallaran durante el despliegue.

#### Características

- Añadir la aplicación Phoenix con inicio de sesión OAuth, mejoras de documentación y mejoras de la interfaz de usuario.
- Usar el logotipo redondeado como favicon.
- Migrar CLI a Bun y actualizar las compilaciones ejecutables de CI.

## 0.1.0

*2026-02-12*

#### Correcciones de errores

- Prevenir el desbordamiento horizontal de los fragmentos de código en móviles.
- Añadir el margen derecho adecuado a los fragmentos de código en móvil.
- Mejorar la disposición responsiva móvil para evitar el desbordamiento horizontal.
- Aplicar el formato Biome.
- Añadir encabezados de grupo a la plantilla de notas de la versión.
- Actualizar el flujo de traducción desde Bun hasta Rust.
- Alinear el cuerpo de la entrada con el layout de héroe y mejorar el contenido de la entrada del blog.
- Centrar horizontalmente el contenido de la entrada del blog.
- Corregir el pánico al truncar resultados de herramientas de UTF-8 de múltiples bytes.

#### Características

- Añadir herramientas de primera parte y la sección del sitio web.
- Mostrar los pasos de verificación de herramientas.
- Simplificar la salida de progreso.
- Colorar las líneas de progreso.
- Mostrar la actividad de traducción y validación.
- Formatear las líneas de herramientas.
- Hacer el sitio web responsivo con menú móvil y diseño adaptable a múltiples puntos de quiebre.
- Reimplementar CLI en Bun/TypeScript.
- Añadir flujo de trabajo de CI y pruebas.
- Añadir verificación de formato con Biome.
- Añadir sección de Refinamiento Progresivo a la página principal.
- Añadir sección de blog con soporte SEO y la primera publicación.
- Unificar la salida de CLI con formato de verbo alineado a la derecha.
- Colorizar la salida de CLI con formato de mensajes enriquecido.
- Añadir imagen cuadrada de Open Graph y etiquetas meta de tarjeta de Twitter.
- Haz que el agente coordinador sea agéntico con uso de herramientas.
- Reescritura `glossia init` con el Protocolo de Cliente de Agente (ACP).
- Agregar soporte para Gemini, validación automática, seguimiento de tokens y mejoras de fiabilidad.

#### Refactorización

- Divide CI en tareas separadas de formato, verificación de tipos, pruebas y construcción.
- Reescribe CLI desde TypeScript/Bun a Rust.