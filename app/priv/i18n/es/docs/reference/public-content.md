%{
  title: "Contenido público e interfaces del rastreador",
  summary:
    "HTML, Markdown, descubrimiento, caché y límites del rastreador para el sitio web público.",
  category: "referencia",
  section: "platform",
  order: 10
}
---

Glossia expone el contenido web publicado por separado de las superficies de la aplicación de cuenta y proyecto.

## Representaciones

| Interfaz | Comportamiento |
|---|---|
| Una URL HTML publicada | La representación del navegador, con metadatos canónicos y un encabezado de respuesta alternativo `Link` de Markdown. |
| Con `Accept: text/markdown` en esa URL | Una representación de Markdown cuando el tipo de medio explícito tiene calidad positiva y no es menos preferido que `text/html`. |
| La URL de la página con `.md` añadido | Una representación explícita de Markdown, independiente de la preferencia del idioma del navegador. |
| `/index.md` | El resumen de Markdown de la página de inicio. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices de contenido publicado en Markdown. |
| `/changelog.md` | Entradas de registro de cambios publicadas en un solo documento de Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Los documentos legales publicados más recientes. Las URL legales con fecha también admiten `.md`. |

Solo `*/*` no activa Markdown. Las respuestas HTML y las respuestas de Markdown comparten `Vary: Accept` para que los cachés no mezclen las representaciones.

El contenido individual de documentación, blog, características y legales utiliza Markdown escrito en lugar de una conversión del HTML renderizado. Las páginas de índice se generan a partir del inventario publicado; la página de inicio tiene un resumen de Markdown curado. La referencia REST interactiva señala a los lectores hacia la especificación OpenAPI en lugar de incrustar un widget de API exclusivo para el navegador.

## Locales

Inglés sin prefijo. Las URLs de marketing traducidas utilizan prefijos literales: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` y `/zh-hans`. Por ejemplo, `/es/docs/tutorials/getting-started.md` sirve la versión en español cuando se publica.

La URL elige el idioma del contenido de Markdown. `Accept-Language` no redirige una solicitud de Markdown. Una traducción de contenido faltante se basa en su fuente en inglés. El resumen de la página de inicio está actualmente redactado en inglés.

## Descubrimiento

- `/robots.txt` prohíbe por defecto el rastreo y se incluye en el inventario finito de HTML y Markdown publicado, los flujos localizados, los recursos de renderizado en `/assets/`, `/fonts/` y `/images/`, el favicon, y las previas de marketing públicas en `/og/marketing/`. Las imágenes de vista previa de cuenta en `/og/app/` siguen prohibidas. Es una guía para robots de rastreo cooperativos, no un mecanismo de autorización.
- `/sitemap.xml` lista el contenido HTML público canónico con alternanzas locales. Los fragmentos del registro de cambios no son URLs separadas.
- `/llms.txt` introduce Glossia y vincula con documentación pública, guías de características y escritos recientes, incluidos enlaces explícitos de Markdown.
- `/llms-full.txt` exporta el resumen de la página de inicio y el inventario de documentación completo en un solo documento de texto que contiene Markdown.

La autenticación, los paneles de control de cuentas, las APIs y otras respuestas de la aplicación están marcados con `noindex, nofollow`. El contenido publicado exitoso está marcado con `index, follow`; los errores permanecen no indexables. Los archivos de texto de descubrimiento (`/robots.txt`, `/llms.txt` y `/llms-full.txt`) usan `noindex, follow`: los lectores pueden obtenerlos y seguir sus enlaces, pero los motores de búsqueda deberían indexar las páginas canónicas en lugar de una devolución de documentación duplicada.

## Almacenamiento en caché y uso de recursos

Las respuestas de descubrimiento de Markdown y texto incluyen:

| Encabezado | Valor o significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` o `text/plain; charset=utf-8` para texto de descubrimiento. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un digesto de SHA-256 citado de la representación. |
| `X-Markdown-Tokens` | Una estimación aproximada de caracteres divididos por cuatro, redondeados hacia arriba; no una cuenta de tokenizador específica del modelo. |

`If-None-Match` admite la coincidencia de validadores fuertes o débiles, múltiples validadores y `*`. Una coincidencia devuelve `304` sin cuerpo. `HEAD` devuelve encabezados de representación sin cuerpo.

El inventario de Markdown publicado se compila en el lanzamiento. Las solicitudes no realizan traducción de contenido, leen archivos fuente, cargan una cuenta autenticada o renderizan una LiveView. No es necesaria la suplantación de User-Agent para acceder a estas representaciones públicas.

## Límites operativos

La negociación de Markdown no proporciona acceso a los paneles de control de cuenta o proyecto. Los límites de velocidad existentes de navegación de cuenta y las pruebas de Turnstile permanecen como protecciones separadas.

Los límites de velocidad del borde de producción aplican tanto a `GET` como a `HEAD`. Los robots de rastreo verificados aún están limitados por velocidad. Las solicitudes excesivas reciben una respuesta de límite de velocidad en lugar de un desafío del navegador; los lectores deben ir más despacio y volver a intentarlo más tarde. El almacenamiento en caché compartido y las solicitudes condicionales no eximen a los clientes de los límites de velocidad.

Los cambios en la política de robots de rastreo en el repositorio solo entran en vigor después de que se desplieguen la aplicación y la configuración de infraestructura relevante.
