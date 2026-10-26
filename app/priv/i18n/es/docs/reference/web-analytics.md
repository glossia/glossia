%{
  title: "SDK de Analítica",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás de la analítica web de Glossia.",
  category: "referencia",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` sigue disponible por compatibilidad. El guion alojado deriva `/v1/collect` de su propio origen; las integraciones de paquetes deben establecer `endpoint` explícitamente.

Acepta un evento JSON de `@glossia/web` SDK. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas de datos malformadas, de modo que el SDK nunca revela qué proyectos recopilan análisis.

El proyecto se resuelve por el dominio del sitio que declara el fragmento. `d` es autoritativo; cuando falta el servidor, vuelve al anfitrión de `u` (la URL de la página) y luego a las solicitudes `Origin`/`Referer`.

### Cuerpo de solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (p. ej. `example.com`). Enviado por la biblioteca del navegador; la resolución de respaldo se describe anteriormente. |
| `n`   | string | Nombre del evento. Por defecto `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma real de la página (`document.documentElement.lang`). Vacío si no declarado. |
| `al`  | string | Idiomas de traducción separados por comas desde `link[rel="alternate"][hreflang]`, excluyendo `x-default`. |
| `cl`  | string | Idioma seleccionado explícitamente, o vacío cuando no se observó ninguna selección. El SDK canoniza las etiquetas BCP 47 y limita la entrada a 64 caracteres. |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, borrado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *` porque el punto de acceso no acepta credenciales.

## Selección explícita de idioma

`selectLanguage(language)` está disponible como exportación nombrada, en la exportación predeterminada del SDK, y en el objeto global `glossia` del guion alojado. Llámalo después de la inicialización desde un manejador de acción de usuario, antes de la navegación. Las etiquetas de idioma inválidas y las llamadas antes de la inicialización son ignoradas.

El método envía un evento `language_selection` inmediatamente. Su `sl` aún describe la página actual, no el destino. Los eventos posteriores incluyen la elección en `cl` hasta que otra elección explícita la reemplace. Sin una selección observada, `cl` está vacío. La elección se almacena como `__glossia_selected_language` en el mismo origen, por pestaña `sessionStorage`; cuando el almacenamiento falla, se retiene solo en memoria hasta la liberación.

Para los enlaces, `data-glossia-language="zh-Hans"` habilita el seguimiento delegado de clics primarios confiables y no modificados, incluida la activación por teclado. Los clics programados, los clics ya cancelados, las descargas, los enlaces cross-origin y los enlaces que apuntan a otra pestaña o marco se ignoran. La escucha se ejecuta en la fase de captura antes de que los enrutadores naveguen, no evita la navegación y también maneja los vínculos insertados dinámicamente. Use ya sea la anotación o la API para una acción, no ambas.

Esta es una señal de intención notificada por el cliente, no una prueba de que la navegación tuvo éxito. Los cambios en la URL, las redirecciones y los cambios en el idioma HTML no se interpretan como elecciones. La selección no sobreescribe `l` ni `sl`, o cambia actualmente `has_locale_gap` ni las insignias del tablero.

## Campos derivados del servidor

Estos se calculan al momento de la ingestión y se almacenan en el lado del servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diario de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alfanumérico alpha-2 desde un encabezado confiable `CF-IPCountry` o el adaptador de geolocalización de IP configurado. Vacío cuando ninguno resuelve un país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de página      | Anfitrión en minúsculas.                                                    |
| `pathname`        | URL de página      | Componente de ruta.                                                     |
| `referrer_source` | Remitente      | Anfitrión del remitente, los prefijos `www.`/`m.` eliminados.                        |
| `browser_language`| Idiomas     | Local más normalizado preferido (por ejemplo, `pt-BR`).                    |
| `served_locale`   | Idioma de página | Normalizado `sl`, o vacío si no se recopiló. Las filas con un idioma de página vacío se omiten del desglose de idiomas del navegador. |
| `selected_locale` | Elección explícita | Normalizado `cl`, o vacío para entrada faltante, incorrecta o sobre-dimensionada. Almacenado por separado de la preferencia del navegador y el idioma de página. |
| `has_locale_gap`  | Calculado      | `1` cuando ninguno de los idiomas preferidos del visitante coinciden con los objetivos del proyecto, las traducciones anunciadas (`al`) o el idioma de página (`sl`). Las preferencias faltantes no cuentan como una brecha. |

### Resolución de IP del cliente

Para solicitudes desde un par de ingress privado, Glossia utiliza el encabezado `X-Real-IP` sobrescrito de nginx, no la primera entrada controlada por el llamante en `X-Forwarded-For`. Las conexiones públicas directas usan la dirección de socket. En Hetzner, tanto el equilibrador de carga como nginx deben habilitar el protocolo PROXY para que nginx reciba la dirección del visitante en lugar de la del equilibrador de carga. Otros proxies inversos también deben sobrescribir `X-Real-IP` usando una fuente autenticada, no un encabezado `X-Forwarded-For` inbound ilimitado. Solo la política de encabezados forward del gráfico genérico no garantiza esto. Los pares privados son infraestructura confiable, por lo que restrinja el acceso directo de contenedores.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` sobreescriba la dirección canónica para solicitudes desde un par de ingress privado. Está **desactivado por defecto**, independientemente de la confianza en el encabezado de país. Habilita solo después de que el borde autentique Cloudflare o elimine encabezados falsificados en solicitudes que evaden Cloudflare. Las implementaciones DNS-only deben dejarlo desactivado. Esta dirección también es clave para límites de tasa de IP y el hash diario del visitante.

### Resolución de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita el camino rápido `CF-IPCountry`. Está **desactivado por defecto**. Habílita solo después de que el origen autentique Cloudflare, rechace solicitudes que evadan Cloudflare, o el ingress elimine copias no confiables del encabezado. La configuración de Geolocalización de IP de Cloudflare también debe estar habilitada para la zona. `CF-Connecting-IP`, `CF-Ray`, y nginx `use-forwarded-headers` no autentican una solicitud por sí solos.

Cuando la confianza de encabezado está habilitada, un solo código ISO de país válido se usa inmediatamente, sin búsqueda de IP o acceso a caché. El valor actual del borde siempre tiende precedencia sobre cualquier búsqueda en caché. Códigos faltantes, duplicados, incorrectos o desconocidos, incluidos los valores `XX` (desconocido) y `T1` (Tor) de Cloudflare, vuelven al adaptador de geolocalización configurado.

Sin una base de datos MaxMind configurada, las búsquedas de respaldo usan `api.ipapi.is`, luego `api.country.is` cuando la solicitud principal falla o devuelve ningún país reconocido. Cada solicitud tiene un tiempo de conexión y respuesta de un segundo con reintentos deshabilitados. Los resultados exitosos de ambos proveedores se cachean por Cachex por 24 horas, con un límite de tamaño programado de 100,000 entradas y reclamo de expiración automático. `Cachex.fetch/3` colapsa aciertos concurrentes para la misma IP en un solo resolutivo. Los fallos no se cachean. Las direcciones privadas y reservadas no se envían a ningún proveedor.

### Idioma de página faltante

El desglose de idiomas del navegador omite eventos sin `sl`. Esto incluye eventos recopilados por versiones antiguas de rastreador y páginas sin un atributo HTML `lang`. Estos eventos aún contribuyen al tráfico general. El idioma de página no se infiere de preferencias del navegador o la URL. Los eventos históricos conservan los metadatos recopilados en ese momento; nuevas versiones de rastreador no las repoblautan.

## Modelo de privacidad

- **No hay identificador persistente cross-session.** El SDK no establece cookies y almacena solo un ID de sesión por pestaña y un idioma seleccionado explícitamente en `sessionStorage`, que el navegador borra al cerrar.
- **No hay huellas digitales.** Huellas digitales de Canvas, WebGL, fuente y audio no se recopilan. El hash rotativo diario del servidor proporciona unicidades sin ellas.
- **No hay identificadores crudos persistentes.** IP y User-Agent se leen una vez, se hashan con un secreto del servidor y una sal diaria, luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos produce IDs de visitante no relacionados, por lo que los visitantes no pueden rastrearse entre clientes de Glossia.
