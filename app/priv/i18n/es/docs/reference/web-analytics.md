%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás del análisis web de Glossia.",
  category: "Referencia",
  section: "analytics",
  order: 1
}
---

## ## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` sigue disponible para compatibilidad. El script alojado deriva `/v1/collect` de su propio origen; las integraciones de paquete deben configurar `endpoint` explícitamente.

Acepta un evento JSON del SDK `@glossia/web`. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas de datos mal formadas, para que el SDK nunca revele qué proyectos recopilan análisis.

El proyecto se resuelve mediante el dominio del sitio que el fragmento declara. `d` es autoritativo; cuando está ausente, el servidor recurre al host de `u` (la URL de la página) y luego las cabeceras `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (p. ej. `example.com`). Enviado por la biblioteca del navegador; la resolución de respaldo se describe arriba. |
| `n`   | string | Nombre del evento. Predeterminado a `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma real de la página (`document.documentElement.lang`). Vacío si no está declarado. |
| `al`  | string | Idiomas de traducción separados por comas procedentes de `link[rel="alternate"][hreflang]`, excluyendo `x-default`. |
| `tz`  | string | Fuso horario IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, borrado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Se computan en la ingestión y se almacenan del lado del servidor. La IP cruda y User-Agent nunca se almacenan.

| Campo             | Fuente        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alfa-2 procedente de un encabezado `CF-IPCountry` de confianza, o del adaptador de geolocalización IP configurado. Vacío cuando ninguno resuelve un país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` o `unknown`.        |
| `hostname`        | URL de la página      | Host en minúsculas.                                                    |
| `pathname`        | URL de la página      | Componente de ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, con `www.`/`m.` inicial eliminado.                        |
| `browser_language`| User-Agent     | Entorno local normalizado preferido (p. ej. `pt-BR`).                    |
| `served_locale`   | Idioma de la página | Normalizado `sl`, o vacío (mostrado como No reportado) si no se recopiló. |
| `has_locale_gap`  | Calculado      | `1` cuando ninguna de las preferencias del visitante coincide con los objetivos del proyecto, las traducciones anunciadas (`al`) o el idioma de la página (`sl`). Las preferencias faltantes no se cuentan como una brecha. |

### Resolución de IP del cliente

Para solicitudes desde un par de acceso privado interno, Glossia utiliza el encabezado `X-Real-IP` sobrescrito de nginx, no la primera entrada controlada por el solicitante en `X-Forwarded-For`. Las conexiones públicas directas usan la dirección del socket. En Hetzner, tanto el equilibrador de carga como nginx deben habilitar el PROXY protocol para que nginx reciba la dirección del visitante en lugar de la del equilibrador de carga. Otros proxies inversos también deben sobrescribir `X-Real-IP` usando una fuente autenticada, no un encabezado inbound `X-Forwarded-For` sin restricción. La política del encabezado transferido de la tabla genérica por sí sola no garantiza esto. Los pares privados son infraestructura de confianza, por lo que se restringe el acceso directo a los pods.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` sobrescriba la dirección canónica para solicitudes desde un par de acceso privado interno. Está **desactivado por defecto**, independientemente de la confianza en el encabezado de país. Habilítelo solo después de que el borde autentifique Cloudflare o elimine encabezados falsificados en solicitudes que eludan Cloudflare. Los despliegues DNS solo deben dejarlo desactivado. Esta dirección también determina los límites de tasa de IP y el hash de visitante diario.

### Resolución de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita la vía rápida `CF-IPCountry`. Está **desactivado por defecto**. Habilítelo solo después de que el origen autentifique Cloudflare, rechace las solicitudes que eludan Cloudflare o el ingreso elimine copias no confiables del encabezado. El ajuste de Geolocalización IP de Cloudflare también debe habilitarse para la zona. `CF-Connecting-IP`, `CF-Ray` y `use-forwarded-headers` de nginx no autentifican una solicitud por sí solos.

Cuando se habilita la confianza en encabezados, se usa inmediatamente un solo código de país ISO válido, sin búsqueda de IP o acceso a caché. El valor actual del borde siempre tiene precedencia sobre cualquier búsqueda en caché. Los códigos faltantes, duplicados, malformados o desconocidos, incluidos los valores `XX` (desconocido) y `T1` (Tor) de Cloudflare, recurren al adaptador de geolocalización configurado.

Sin una base de datos de MaxMind configurada, las búsquedas de reemplazo utilizan `api.ipapi.is`, luego `api.country.is` cuando la solicitud principal falla o devuelve ningún país reconocido. Cada solicitud tiene un tiempo de conexión y respuesta de un segundo sin reintentos. Los resultados exitosos de cualquiera de los proveedores se almacenan con Cachex durante 24 horas, con un límite de tamaño programado de 100,000 entradas y reclamation por caducidad automática. `Cachex.fetch/3` agrupa las búsquedas concurrentes fallidas para la misma IP en un solo resolutor. Los fallos no se almacenan. Las direcciones privadas y reservadas no se envían a ningún proveedor.

### Idioma de página ausente

El panel de control muestra **No reportado** cuando un evento no tiene `sl`. Esto incluye eventos recopilados por versiones más antiguas del rastreador y páginas sin el atributo HTML `lang`. El idioma de la página no se infiere de las preferencias del navegador o de la URL. Los eventos históricos mantienen los metadatos recopilados en ese momento; las nuevas versiones del rastreador no las rellenan.

## Modelo de privacidad

- **No hay un identificador persistente entre sesiones.** El SDK no establece cookies y almacena solo un ID de sesión por pestaña en `sessionStorage`, que el navegador borra al cerrar.
- **Sin rastreo de huellas.** Canvas, WebGL, fuentes y huellas de audio no se recopilan. El hash rotado diariamente del servidor proporciona identificadores únicos sin ellas.
- **No se almacenan identificadores crudos.** IP y User-Agent se leen una vez, se hash con una clave del servidor y una sal diaria, luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos produce IDs de visitantes no relacionados, por lo que los visitantes no pueden rastrearse entre clientes de Glossia.
