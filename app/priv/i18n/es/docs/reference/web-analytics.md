%{
  title: "SDK de analítica",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás de la analítica web de Glossia.",
  category: "Referencia",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Acepta un evento JSON desde el `@glossia/web` SDK. Siempre responde `202 Accepted`, incluyendo para dominios desconocidos o cargas malformadas, por lo que el SDK nunca revela qué proyectos recopilan análisis.

El proyecto se resuelve por el dominio del sitio que declara el fragmento. `d` es autoritativo; cuando falta, el servidor recurre al host de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (ej. `example.com`). Obligatorio. |
| `n`   | string | Nombre del evento. Por defecto `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`)         |
| `tz`  | cadena | zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, borrado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan en la ingestión y se almacenan en el servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                        |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | hash rotado diariamente de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | GeoIP         | código ISO 3166-1 alpha-2. Vacío cuando GeoIP no está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | Agente de usuario    | `chrome`, `safari`, `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | Agente de Usuario    | `windows`, `macos`El documento reensamblado previamente falló en la validación: la recuperación del texto literal de Markdown devolvió JSON inválido `ios`El documento reensamblado falló en la validación: la recuperación del texto literal de Markdown devolvió un JSON inválido. `android`, `linux`, o, `unknown`.        |
| `hostname`        | URL de página      | host en minúsculas.                                                    |
| `pathname`        | URL de página      | componente de ruta.                                                     |
| `referrer_source` | Referer      | Referer host, inicial `www.`|`m.` eliminado.                        |
| `browser_language`| Idiomas     | Idioma normalizado preferido (ej. `pt-BR`).                    |
| `served_locale`   | Calculado      | Primera meta soportada coincidente con un idioma preferido, de lo contrario vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un lenguaje que el proyecto no sirve. |

## Modelo de privacidad

- **No almacenamiento del lado del cliente.** El SDK no establece cookies y solo guarda un id de sesión por pestaña en `sessionStorage`, que el navegador limpia al cerrar.
- **No rastreo de huellas.** No se recogen las huellas dactilares de Canvas, WebGL, fuentes y audio. El hash rotativo diario del servidor proporciona identificadores únicos sin ellas.
- **No se persisten identificadores en bruto.** La IP y el User-Agent se leen una sola vez, se procesan mediante un hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera identificadores de visitante no relacionados, por lo que los visitantes no pueden ser rastreados entre clientes de Glossia.