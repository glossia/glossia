%{
  title: "SDK Analítico",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad que respalda la analítica web de Glossia.",
  category: "Referencia",
  section: "analytics",
  order: 1
}
---

## Punto de conexión de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` sigue disponible para la compatibilidad. El script alojado deriva `/v1/collect` de su propio origen; las integraciones de paquete deben establecer `endpoint` explícitamente.

Acepta un evento JSON del SDK `@glossia/web`. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas malformadas, por lo que el SDK nunca revela qué proyectos recopilan analíticas.

El proyecto se resuelve por el dominio del sitio que declara el fragmento. `d` es la autoridad; cuando está ausente, el servidor vuelve al host de `u` (la URL de la página) y luego a la solicitud `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (por ejemplo, `example.com`). Enviado por la biblioteca del navegador; la resolución de respaldo se describe anteriormente. |
| `n`   | string | Nombre del evento. Predeterminado a `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma de la página actual (`document.documentElement.lang`). Vacío si no está declarado. |
| `al`  | string | Idiomas de traducción separados por comas desde `link[rel="alternate"][hreflang]`, excluyendo `x-default`. |
| `tz`  | string | Fuso horario IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, se borra al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el punto de conexión no acepta credenciales.

## Campos derivados del servidor

Estos se calculan durante la ingestión y se almacenan a nivel de servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diario de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 desde un encabezado `CF-IPCountry` de confianza, o el adaptador de geolocalización IP configurado. Vacío cuando ninguno resuelve un país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` o `unknown`.        |
| `hostname`        | URL de la página      | Host en minúsculas.                                                    |
| `pathname`        | URL de la página      | Componente de ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, con `www.`/`m.` inicial eliminado.                        |
| `browser_language`| Idiomas     | Localización preferida más normalizada (p. ej. `pt-BR`).                    |
| `served_locale`   | Idioma de la página | Localización normalizada `sl`, o vacío (mostrado como Not reported) si no se recopiló. |
| `has_locale_gap`  | Computado      | .`1` cuando ninguno de los idiomas preferidos del visitante coinciden con los objetivos del proyecto, las traducciones anunciadas (`al`), o el idioma de la página (`sl`). Las preferencias faltantes no se cuentan como una brecha. |

### Resolución de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita la ruta rápida `CF-IPCountry`. Es **deshabilitado por defecto**. Habilítelo solo después de que el origen autentique Cloudflare, rechace las solicitudes que sorteen Cloudflare, o el ingreso elimine copias no confiables del encabezado. La configuración de Geolocalización IP de Cloudflare también debe estar habilitada para la zona. `CF-Connecting-IP`, `CF-Ray` y `use-forwarded-headers` de nginx no autentican una solicitud por sí solos.

Cuando se habilita la confianza en el encabezado, se usa inmediatamente un único código ISO válido de país, sin una búsqueda de IP ni acceso a caché. El valor actual del borde siempre tiene prioridad sobre cualquier búsqueda en caché. Los códigos faltantes, duplicados, malformados o desconocidos, incluidos los valores `XX` (desconocido) y `T1` (Tor) de Cloudflare, vuelven al adaptador de geolocalización configurado.

Sin una base de datos MaxMind configurada, las búsquedas de reflujo usan `api.ipapi.is`, luego `api.country.is` cuando la solicitud principal falla o no devuelve ningún país reconocido. Cada solicitud tiene un tiempo de conexión y respuesta de un segundo con reintentos deshabilitados. Los resultados exitosos de cualquiera de los proveedores se almacenan en Cachex durante 24 horas, con un límite de tamaño programado de 100,000 entradas y reclamo automático de expiración. `Cachex.fetch/3` colapsa las pérdidas concurrentes para la misma IP en un solo resolutor. Los fallos no se almacenan. Las direcciones privadas y reservadas no se envían a ninguno de los proveedores.

### Idioma de la página faltante

El panel de control muestra **Not reported** cuando un evento no tiene `sl`. Esto incluye eventos colectados por versiones antiguas del rastreador y páginas sin un `lang` HTML. El idioma de la página no se infiere de las preferencias del navegador o la URL. Los eventos históricos conservan los metadatos recopilados en el momento; las versiones nuevas del rastreador no los subsanan.

## Modelo de privacidad

- **No hay un identificador persistente inter-sesiones.** El SDK no establece cookies y almacena solo un id de sesión por pestaña en `sessionStorage`, que el navegador borra al cerrar.
- **No hay huellas dactilares.** No se recopilan huellas de Canvas, WebGL, fuentes y audio. El hash del servidor rotativo de día proporciona unicidades sin ellas.
- **No se conservan identificadores crudos.** La IP y User-Agent se leen una vez, se hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos produce IDs de visitante no relacionados, por lo que los visitantes no pueden ser rastreados a través de los clientes de Glossia.
