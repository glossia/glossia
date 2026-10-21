%{
  title: "Contenido público e interfaces de rastreadores",
  summary:
    "HTML, Markdown, descubrimiento, caché y límites de los rastreadores para el sitio web público.",
  category: "referencia",
  section: "platform",
  order: 10
}
---

Glossia expone el contenido publicado del sitio web por separado de las superficies de aplicación de cuentas y proyectos.

## Representaciones

| Interfaz | Comportamiento |
|---|---|
| Un URL HTML publicado | La representación del navegador, con metadatos canónicos y un encabezado de respuesta Markdown alternativo `Link` |
| `Accept: text/markdown` en esa URL | Una representación Markdown cuando el tipo de medio explícito tiene calidad positiva y no es menos preferido que `text/html`. |
| El URL de la página con `.md` añadido | Una representación Markdown explícita, independiente de la preferencia de idioma del navegador. |
| `/index.md` | El resumen Markdown de la página de inicio. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices Markdown del contenido publicado. |
| `/changelog.md` | Entradas del registro de cambios publicadas en un solo documento Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Los últimos documentos legales publicados. Los URL legales con fecha también soportan `.md`. |

El uso exclusivo de `*/*` no habilita el Markdown. Las respuestas HTML y Markdown comparten `Vary: Accept` para que las caches no mezclen las representaciones.

El contenido individual de documentación, blog, funciones y legales utiliza Markdown redactado en lugar de una conversión del HTML renderizado. Las páginas de índice se generan a partir del inventario publicado; la página de inicio tiene un resumen Markdown curado. El referencial REST interactivo señala a los lectores a la especificación OpenAPI en lugar de incrustar un widget de API solo para navegador.

## Localizaciones

El idioma inglés no tiene prefijo. Los URL de marketing traducidos usan prefijos literales: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` y `/zh-hans`. Por ejemplo, `/es/docs/tutorials/getting-started.md` sirve la versión en español cuando se publica.

El URL elige el idioma del contenido Markdown. `Accept-Language` no redirige una solicitud Markdown. Una traducción de contenido faltante recurre a su fuente en inglés. El resumen de la página de inicio está actualmente redactado en inglés.

## Descubrimiento

- `/robots.txt` predetermina deshabilitar la exploración y se inscribe en el inventario publicado finito de HTML y Markdown, canales localizados, activos de renderizado bajo `/assets/`, `/fonts/` y `/images/`, el favicon, y previos de marketing públicos bajo `/og/marketing/`. Las imágenes de vista previa de cuenta bajo `/og/app/` permanecen prohibidas. Es una guía para crawlers cooperativos, no un mecanismo de autorización.
- `/sitemap.xml` lista el contenido HTML público canónico con alternates de localización. Los fragmentos del registro de cambios no son URL separadas.
- `/llms.txt` presenta a Glossia y enlaza a documentación pública, guías de características y escritos recientes, incluyendo enlaces Markdown explícitos.
- `/llms-full.txt` exporta el resumen de la página de inicio y el inventario de documentación completo en un solo documento de texto que contiene Markdown.

Autenticación, paneles de gestión de cuentas, APIs y otras respuestas de aplicación están marcadas `noindex, nofollow`. El contenido publicado exitoso está marcado `index, follow`; los errores permanecen no indexables. Los archivos de texto de descubrimiento (`/robots.txt`, `/llms.txt` y `/llms-full.txt`) usan `noindex, follow`: los lectores pueden recuperarlos y seguir sus enlaces, pero los motores de búsqueda deberían indexar las páginas canónicas en lugar de una duplicación de documentación.

## Almacenamiento en caché y uso de recursos

Las respuestas de descubrimiento Markdown y de texto incluyen:

| Cabecera | Valor o significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` o `text/plain; charset=utf-8` para texto de descubrimiento. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un resumen citado SHA-256 de la representación. |
| `X-Markdown-Tokens` | Una estimación aproximada de caracteres divididos por cuatro, redondeados hacia arriba; no es un conteo de tokenizador específico del modelo. |

`If-None-Match` soporta coincidir con validadores fuertes o débiles, múltiples validadores y `*`. Una coincidencia devuelve `304` sin un cuerpo. `HEAD` devuelve encabezados de representación sin un cuerpo.

El inventario Markdown publicado se compila en la versión. Las solicitudes no realizan traducción de contenido, leer archivos fuente, cargar una cuenta autenticada o renderizar un LiveView. No se requiere impersonación del User-Agent para acceder a estas representaciones públicas.

## Límites operativos

La negociación Markdown no proporciona acceso a los paneles de cuenta o proyecto. Los límites de velocidad de exploración de cuenta existentes y las comprobaciones de Turnstile permanecen como protecciones separadas.

Los límites de velocidad del borde de producción se aplican a `GET` y `HEAD`. Los crawlers verificados siguen teniendo límites de velocidad. Las solicitudes excesivas reciben una respuesta de límite de velocidad en lugar de un desafío del navegador; los lectores deben desacelerarse y volver a intentarlo más tarde. El almacenamiento en caché compartido y las solicitudes condicionales no eximen a los clientes de los límites de velocidad.

Los cambios de política de crawler en el repositorio entran en vigor solo después de que se despliegan la aplicación y la configuración de infraestructura relevante.
