%{
  title: "Contenido público e interfaces de rastreo",
  summary:
    "HTML, Markdown, descubrimiento, caché y límites de rastreo para el sitio web público.",
  category: "referencia",
  section: "platform",
  order: 10
}
---

Glossia presenta el contenido web publicado por separado de las superficies de cuenta y proyecto de la aplicación.

## Representaciones

| Interfaz | Comportamiento |
|---|---|
| Una URL HTML publicada | La representación del navegador, con metadatos canónicos y un encabezado de respuesta Markdown alterno `Link`. |
| Al especificar `Accept: text/markdown` en esa URL | Una representación Markdown cuando el tipo de medio explícito tiene calidad positiva y no es menos preferido que `text/html`. |
| La URL de la página con `.md` adjunto | Una representación Markdown explícita, independiente de la preferencia de idioma del navegador. |
| `/index.md` | La descripción general Markdown de la página principal. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices Markdown del contenido publicado. |
| `/changelog.md` | Entradas de registro publicadas en un solo documento Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Documentos legales publicados más recientes. Las URLs legales con fecha también admiten `.md`. |

Solamente `*/*` no activa el Markdown. Las respuestas HTML y Markdown comparten `Vary: Accept` para que las cachés no mezclen las representaciones.

El contenido individual de documentación, blog, característica y legal utiliza Markdown redactado en lugar de una conversión del HTML renderizado. Las páginas de índice se generan a partir del inventario publicado; la página principal tiene una descripción general Markdown curada. La referencia interactiva REST señala a los lectores la especificación OpenAPI en lugar de incrustar un widget de API exclusivo para el navegador.

## Localizaciones

El inglés no lleva prefijo. Las URLs de marketing traducidas usan prefijos literales: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` y `/zh-hans`. Por ejemplo, `/es/docs/tutorials/getting-started.md` ofrece la versión en español cuando se publica.

La URL elige el idioma del contenido Markdown. `Accept-Language` no redirige una solicitud Markdown. Una traducción de contenido faltante recurre a su origen inglés. La descripción general de la página principal está actualmente redactada en inglés.

## Descubrimiento

- Por defecto, `/robots.txt` prohíbe el rastreo e incluye el inventario finito HTML y Markdown publicado, feeds localizados, activos de renderizado bajo `/assets/`, `/fonts/` y `/images/`, el favicon, y las vistas previas de marketing públicas bajo `/og/marketing/`. Las imágenes de vista previa de cuenta bajo `/og/app/` siguen prohibidas. Es una guía para rastreadores cooperativos, no un mecanismo de autorización.
- `/sitemap.xml` enumera el contenido público canónico con alternativos de idioma, incluyendo URLs Markdown para páginas solo en Markdown. Los fragmentos de registro no son URLs separadas.
- `/llms.txt` presenta Glossia y enlaza con documentación pública, guías de función y escritura reciente, incluyendo enlaces Markdown explícitos.
- `/llms-full.txt` exporta la descripción general de la página principal, documentación y contenido de comparación solo en Markdown en un documento de texto que contiene Markdown.

El contenido de comparación se publica solo como Markdown. Permanece fuera de la documentación HTML, la navegación, la búsqueda y los índices de documentación, pero los agentes pueden descubrirlo a través de `/llms.txt` y el sitemap. Su URL canónica termina con `.md`; la URL HTML anterior también responde a `Accept: text/markdown`, pero ya no renderiza una página del navegador.

La autenticación, paneles de administración de cuenta, APIs y otras respuestas de la aplicación tienen marcado `noindex, nofollow`. El contenido exitoso publicado tiene marcado `index, follow`; los errores permanecen no indexables. Los archivos de texto de descubrimiento (`/robots.txt`, `/llms.txt` y `/llms-full.txt`) usan `noindex, follow`: los lectores pueden obtenerlos y seguir sus enlaces, pero los motores de búsqueda deben indexar las páginas canónicas en lugar de un volcado duplicado de documentación.

## Almacenamiento en caché y uso de recursos

Las respuestas de descubrimiento Markdown y de texto incluyen:

| Cabecera | Valor o significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` para Markdown, o `text/plain; charset=utf-8` para el texto de descubrimiento. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un resumen SHA-256 citado de la representación. |
| `X-Markdown-Tokens` | Una estimación aproximada de caracteres dividida por cuatro, redondeada hacia arriba; no un conteo de tokenizer específico del modelo. |

`If-None-Match` admite la correspondencia de validadores fuertes o débiles, múltiples validadores y `*`. Un acierto devuelve `304` sin cuerpo. `HEAD` devuelve encabezados de representación sin cuerpo.

El inventario Markdown publicado se compila en el lanzamiento. Las solicitudes no realizan traducción de contenido, leen archivos fuente, cargan una cuenta autenticada o renderizan un LiveView. No se necesita imitación de User-Agent para acceder a estas representaciones públicas.

## Límites operativos

La negociación Markdown no brinda acceso a los paneles de administración de cuenta o proyecto. Los límites de velocidad existentes de navegación de cuenta y las verificaciones de Turnstile permanecen como protecciones separadas.

Los límites de velocidad de borde de producción aplican tanto a `GET` como a `HEAD`. Los rastreadores verificados siguen limitados por la velocidad. Las solicitudes excesivas reciben una respuesta de límite de velocidad en lugar de un desafío del navegador; los lectores deben reducir la velocidad y reintentar más tarde. El almacenamiento en caché compartido y las solicitudes condicionales no eximen a los clientes de los límites de velocidad.

Los cambios en la política de rastreadores en el repositorio surten efecto solo después de que la aplicación y la configuración de infraestructura relevante se hayan implementado.
