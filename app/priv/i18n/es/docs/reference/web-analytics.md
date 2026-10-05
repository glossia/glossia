%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad de la analítica web de Glossia.",
  category: "referencia",
  section: "analytics",
  order: 1
}
---
## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` sigue disponible para compatibilidad. El script alojado deriva `/v1/collect` de su propio origen; las integraciones de paquetes deben configurar `endpoint` explícitamente.

Acepta un evento JSON de `@glossia/web` el SDK. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas malformadas, por lo que el SDK nunca revela qué proyectos recopilan datos analíticos.

El proyecto se resuelve según el dominio del sitio que declara el fragmento. `d` es autoritativo; cuando está ausente, el servidor recurre al host de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | cadena | Dominio del sitio que identifica el proyecto (ej.,") Enviado por la librería del navegador; la resolución de respaldo se describe anteriormente. | `example.com`|
| `n`   | cadena | Nombre del evento. Por defecto `pageview`.                          |
| `u`   | cadena | URL de página (`location.href`) .                                  |
| `r`   | string | Referidor (`document.referrer`),                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`),         |
| `sl`  | string | Idioma actual de la página (`document.documentElement.lang`). Vacío si no declarado. |
| `al`  | string | Idiomas de traducción separados por comas desde `link[rel="alternate"][hreflang]`, excluyendo `x-default`. |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, se vacía al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`icion que el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan en la ingestión y se almacenan en el servidor. La IP cruda y User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | Cloudflare / GeoIP | código ISO 3166-1 alpha-2 de una confiable `CF-IPCountry` cabecera, o el adaptador de geolocalización de IP configurado. Vacío cuando ninguno resuelve un país. |
| `device`          | Agente de usuario    | `desktop`, `mobile`, `tablet`The reassembled document previously failed validation: Markdown text-literal recovery returned invalid JSON `bot`, o `unknown`.                 |
| `browser`         | Agente de Usuario    | `chrome`, `safari`, `firefox`El documento reensamblado falló previamente la validación: la recuperación del literal de texto Markdown debe devolver un array de cadenas JSON de longitud coincidente `edge`El documento reensamblado anteriormente no pasó la validación: la recuperación de texto literal de Markdown debe devolver un array de cadenas JSON de longitud coincidente `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de página      | Host en minúsculas.                                                    |
| `pathname`        | URL de página      | Componente de ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, inicial `www.`/`m.` eliminado.                        |
| `browser_language`| Idiomas     | Localización preferida normalizada (e.g. `pt-BR`).                    |
| `served_locale`   | Idioma de la página | Normalizado `sl`, o vacío (se muestra como No reportado) si no fue recogido. |
| `has_locale_gap`  | Calculado      | `1` cuando ninguno de los idiomas preferidos del visitante coincide con los objetivos del proyecto, las traducciones anunciadas (`al`), o el idioma de la página (`sl`). Las preferencias faltantes no cuentan como una brecha. |

### Resolución por país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita la `CF-IPCountry` ruta rápida. Es **desactivado por defecto**. Actívalo solo después de que el origen autentique Cloudflare, rechace las solicitudes que salten Cloudflare o el ingreso elimine las copias no confiables del encabezado. La configuración de Geolocalización de IP de Cloudflare también debe estar habilitada para la zona. `CF-Connecting-IP`, `CF-Ray`, y de nginx `use-forwarded-headers` no autentican una solicitud por sí mismas.

Cuando la confianza de encabezados está habilitada, se utiliza inmediatamente un único código de país ISO válido, sin una búsqueda de IP o acceso a caché. El valor actual del borde siempre tiene prioridad sobre cualquier búsqueda en caché. Códigos faltantes, duplicados, malformados o desconocidos, incluidos los de Cloudflare `XX` (desconocido) y `T1` (Tor) valores, recurrir al adaptador de geolocalización configurado.

Sin una base de datos MaxMind configurada, las consultas de respaldo utilizan `api.ipapi.is`, luego `api.country.is` cuando la solicitud principal falla o devuelve ningún país reconocido. Cada solicitud tiene un tiempo límite de conexión y respuesta de un segundo con reintentos desactivados. Los resultados exitosos de cualquiera de los proveedores se almacenan en caché en Cachex durante 24 horas, con un límite de tamaño programado de 100.000 entradas y eliminación automática de elementos expirados. `Cachex.fetch/3` agrupa los intentos fallidos concurrentes para la misma IP en un solo resolver. Los fallos no se almacenan en caché. Las direcciones privadas y reservadas no se envían a ninguno de los proveedores.

### Idioma de la página faltante

El panel de control muestra **No reportado** cuando un evento no tiene `sl`. Esto incluye eventos recopilados por versiones anteriores del rastreador y páginas sin un HTML `lang` atributo. El idioma de la página no se infiere de las preferencias del navegador ni de la URL. Los eventos históricos mantienen el metadatos recopilado en el momento; las nuevas versiones del rastreador no las rellenan retrospectivamente.

## Modelo de privacidad

- **No hay un identificador persistente entre sesiones.** El SDK no establece cookies y solo almacena un id de sesión por pestaña en `sessionStorage`, que el navegador borra al cerrar.
- **Sin rastreo por huellas.** No se recopilan las huellas de Canvas, WebGL, fuentes y audio. El hash del servidor rotado diariamente proporciona identificadores únicos sin ellas.
- **No se persisten identificadores crudos.** La IP y el User-Agent se leen una vez, se someten a hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera identificadores de visitantes no relacionados, por lo que los visitantes no pueden ser rastreados entre los clientes de Glossia.