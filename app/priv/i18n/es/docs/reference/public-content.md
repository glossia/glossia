%{
  title: "Contenido público e interfaces de rastreadores",
  summary:
    "HTML, Markdown, descubrimiento, caché y límites de rastreadores para el sitio web público.",
  category: "referencia",
  section: "platform",
  order: 10
}
---

Glossia expone el contenido web publicado por separado de las superficies de la aplicación de cuentas y proyectos.

## Representaciones

| Interfaz | Comportamiento |
|---|---|
| Una URL HTML publicada | La representación del navegador, con metadatos canónicos y una cabecera de respuesta Markdown alternativa `Link`. |
| `Accept: text/markdown` en esa URL | Una representación Markdown cuando el tipo de medios explícito tiene calidad positiva y no es menos preferido que `text/html`. |
| La URL de la página con `.md` adjuntada | Una representación Markdown explícita, independiente de la preferencia del idioma del navegador. |
| `/index.md` | La descripción general de la página de inicio en Markdown. |
| `/docs.md`, `/blog.md`, `/features.md` | Índices Markdown del contenido publicado. |
| `/changelog.md` | Entradas de changelog publicadas en un solo documento Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Los últimos documentos legales publicados. Las URL legales con fecha también admiten `.md`. |

Solo `*/*` no habilita Markdown. Las respuestas HTML y Markdown comparten `Vary: Accept` para que las cachés no mezclen las representaciones.

El contenido individual de documentación, blog, funcionalidad y legales utiliza Markdown escrito en lugar de una conversión del HTML renderizado. Las páginas de índice se generan a partir del inventario publicado; la página de inicio tiene una descripción general de Markdown curada. La referencia REST interactiva orienta a los lectores hacia la especificación OpenAPI en lugar de incrustar un widget de API exclusivo para el navegador.

## Localizaciones

El inglés no tiene prefijo. Las URL de marketing traducidas utilizan prefijos literales: `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br`, y `/zh-hans`. Por ejemplo, `/es/docs/tutorials/getting-started.md` sirve la versión en español cuando está publicada.

La URL determina el idioma del contenido Markdown. `Accept-Language` no redirige una solicitud Markdown. Si falta una traducción de contenido, recurre a su fuente en inglés. El resumen de la página de inicio actualmente está escrito en inglés.

## Descubrimiento

- `/robots.txt` por defecto bloquea el rastreo y autoriza el inventario HTML y Markdown publicado, los feeds localizados, los recursos renderizados bajo `/assets/`, `/fonts/` y `/images/`, el favicon y las vistas previas de marketing público bajo `/og/marketing/`. Las imágenes de vista previa de cuenta bajo `/og/app/` permanecen prohibidas. Es una guía para rastreadores cooperativos, no un mecanismo de autorización.
- `/sitemap.xml` lista el contenido público canónico con alternativas de idioma, incluyendo URLs Markdown para páginas solo Markdown. Los fragmentos de changelog no son URLs separadas.
- `/llms.txt` introduce Glossia y enlaza a la documentación pública, guías de funcionalidad y escritura reciente, incluyendo enlaces Markdown explícitos.
- `/llms-full.txt` exporta la descripción general de la página de inicio, la documentación y el contenido de comparación solo Markdown en un documento de texto que contiene Markdown.

El contenido de comparación se publica como Markdown solo. Se queda fuera de la documentación HTML, la navegación, el buscador y los índices de documentación, pero los agentes pueden descubrirlo a través de `/llms.txt` y el sitemap. Su URL canónica termina en `.md`; la URL HTML anterior también responde a `Accept: text/markdown`, pero ya no renderiza una página de navegador.

La autenticación, paneles de control de cuentas, APIs y otras respuestas de aplicación marcan `noindex, nofollow`. El contenido publicado exitoso marca `index, follow`; los errores permanecen no indexables. Los archivos de texto de descubrimiento (`/robots.txt`, `/llms.txt` y `/llms-full.txt`) usan `noindex, follow`: los lectores pueden recuperarlos y seguir sus enlaces, pero los motores de búsqueda deben indexar las páginas canónicas en lugar de una descarga de documentación duplicada.

## Caché y uso de recursos

Las respuestas de descubrimiento Markdown y texto incluyen:

| Cabecera | Valor o significado |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` o `text/plain; charset=utf-8` para el texto de descubrimiento. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un resumen SHA-256 citado de la representación. |
| `X-Markdown-Tokens` | Una estimación aproximada de caracteres dividida por cuatro, redondeada hacia arriba; no es un conteo de tokenizador específico del modelo. |

`If-None-Match` permite la coincidencia de validadores fuertes o débiles, múltiples validadores y `*`. Una coincidencia devuelve `304` sin cuerpo. `HEAD` devuelve encabezados de representación sin cuerpo.

El inventario Markdown publicado se compila en la versión de lanzamiento. Las solicitudes no realizan traducción de contenido, leen archivos fuente, cargan una cuenta autenticada ni renderizan una LiveView. No es necesario el falsificación del User-Agent para acceder a estas representaciones públicas.

## Límites operacionales

La negociación Markdown no proporciona acceso a los paneles de cuenta o proyecto. Los límites de velocidad de exploración de cuentas existentes y las verificaciones de Turnstile permanecen como protecciones separadas.

Los límites de tasa del borde de producción se aplican tanto a `GET` como a `HEAD`. Los rastreadores verificados siguen sujetos a límites. Las solicitudes excesivas reciben una respuesta de límite de tasa en lugar de un desafío de navegador; los lectores deben reducir la velocidad y reintentar más tarde. El almacenamiento en caché compartido y las solicitudes condicionales no eximen a los clientes de los límites de tasa.

Los cambios de política de rastreo en el repositorio solo tienen efecto después de que la aplicación y la configuración de infraestructura relevante se han desplegado.
