%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás del análisis web de Glossia.",
  category: "Referencia",
  order: 1
}
---
## Endpoint de Eventos

`POST /api/analytics/events`

Acepta un evento JSON de `@glossia/web` SDK. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas malformadas, para que el SDK nunca revele qué proyectos recopilan analíticas.

El proyecto se determina por `d`; cuando está ausente, el servidor recurre al anfitrión de `u` (la URL de la página) y luego a la `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (e. g. `example.com`). Obligatorio. |
| `n`   | string | Nombre del evento. Por defecto `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, borrado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el punto de acceso no acepta credenciales.

## Campos derivados del servidor

Estos se calculan durante la ingestión y se almacenan en el servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No configurable entre días. |
| `country_code`    | GeoIP         | Código ISO 3166-1 alpha-2. Vacío si GeoIP no está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de la página      | Anfitrión en minúsculas.                                                    |
| `pathname`        | URL de la página      | Componente de ruta.                                                     |
| `referrer_source` | Referente      | Anfitrión del referente, eliminando `www.`/`m.`.                        |
| `browser_language`| Idiomas     | Localización normalizada más preferida (e. g. `pt-BR`).                    |
| `served_locale`   | Calculado      | Primer objetivo compatible que coincide con un idioma preferido, de lo contrario vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un idioma que el proyecto no sirve. |

## Modelo de privacidad

- **Sin guardado en el lado del cliente.** El SDK no configura cookies y solo almacena un ID de sesión por pestaña en `sessionStorage`, lo que el navegador borra al cerrar.
- **Sin huella digital.** No se recopilan huellas de Canvas, WebGL, fuentes y audio. El hash rotado diariamente ofrece unicidades sin ellas.
- **Sin identificadores crudos permanentes.** IP y User-Agent se leen una vez, se hashen con un secreto del servidor y una sal diaria, y luego se descartan.
- **Amplicidad por proyecto.** El mismo navegador en dos proyectos produce IDs de visitantes no relacionados, por lo que los visitantes no pueden rastrearse entre los clientes de Glossia.