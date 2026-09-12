%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad que respalda el análisis web de Glossia.",
  category: "referencia",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Acepta un evento JSON desde el `@glossia/web` SDK. Siempre responde `202 Accepted`, incluyendo para dominios desconocidos o cargas malformadas, por lo que el SDK nunca revela qué proyectos recopilan análisis.

El proyecto se resuelve mediante el dominio del sitio que el fragmento declara. `d` es autoritativo; cuando no está presente, el servidor recurre al host de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (e.g. `example.com`). Obligatorio. |
| `n`   | string | Nombre del evento. Por defecto `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`)         |
| `tz`  | cadena | zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, se borra al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan durante la ingestión y se almacenan en el lado del servidor. La IP cruda y User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | GeoIP         | Código ISO 3166-1 alpha-2. Vacío cuando GeoIP no está configurado.        |
| `device`          | Agente de usuario    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de página       | anfitrión en minúsculas.                                                    |
| `pathname`        | URL de página       | componente de ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, inicial `www.`/`m.` eliminado.                        |
| `browser_language`| Idiomas       | Localización preferida normalizada (ej. `pt-BR`).                    |
| `served_locale`   | Computado      | Primer idioma objetivo compatible con un idioma preferido, de lo contrario vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un idioma que el proyecto no ofrece. |

## Modelo de privacidad

- **Sin almacenamiento en el lado del cliente.** El SDK no establece cookies y solo almacena un ID de sesión por pestaña en `sessionStorage`, que el navegador elimina al cerrar.
- **Sin rastreo de huella digital.** Las huellas de Canvas, WebGL, fuentes y audio no se recopilan. El hash del servidor, que rota diariamente, proporciona identificadores únicos sin ellas.
- **No se persisten identificadores crudos.** La IP y el User-Agent se leen una vez, se hashean con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera IDs de visitantes sin relación, por lo que los visitantes no pueden ser rastreados entre clientes de Glossia.