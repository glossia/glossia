%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás de la analítica web de Glossia.",
  category: "Referencia",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Acepta un evento JSON desde el SDK `@glossia/web`. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas malformadas, para que el SDK nunca revele de qué proyectos recopila análisis.

El proyecto se resuelve mediante el dominio del sitio que declara el fragmento. `d` es la fuente autoritativa; cuando falta, el servidor recurre al host de `u` (la URL de la página) y luego al `Origin`/`Referer` de la solicitud.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (ej. `example.com`). Requerido. |
| `n`   | string | Nombre del evento. Por defecto `pageview`.                   |
| `u`   | string | URL de la página (`location.href`).                           |
| `r`   | string | Origen (`document.referrer`).                                 |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).     |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de la pantalla en píxeles CSS.                          |
| `sid` | string | ID de sesión por pestaña (sessionStorage, se borra al cerrar).  |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan en el momento de la ingestión y se guardan en el lado del servidor. La IP cruda y el User-Agent nunca se guardan.

| Campo             | Fuente        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | hash rotado diariamente de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | GeoIP         | Código ISO 3166-1 alpha-2. Vacío cuando GeoIP no está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` o `unknown`.                     |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` o `unknown`.           |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` o `unknown`.            |
| `hostname`        | URL de la página | Host en minúsculas.                                            |
| `pathname`        | URL de la página | Componente del recorrido.                                     |
| `referrer_source` | Origen        | Host del origen, `www.`/`m.` inicial eliminados.                       |
| `browser_language`| Idiomas       | Localización normalizada más preferida (ej. `pt-BR`).                 |
| `served_locale`   | Computed      | Primer objetivo compatible que coincida con un idioma preferido, de lo contrario vacío.   |
| `has_locale_gap`  | Computed      | `1` cuando el visitante prefiere un idioma que el proyecto no sirve.   |

## Modelo de privacidad

- **No almacenamiento en el lado del cliente.** El SDK no configura cookies y almacena solo un ID de sesión por pestaña en `sessionStorage`, que el navegador elimina al cerrar.
- **Sin huellas identificativas.** Las huellas de Canvas, WebGL, fuentes y audio no se recopilan. El hash rotado diariamente del servidor proporciona unicidad sin ellas.
- **Sin persistencia de identificadores crudos.** IP y User-Agent se leen una vez, se hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera ID de visitantes no relacionados, por lo que los visitantes no pueden rastrearse entre clientes de Glossia.