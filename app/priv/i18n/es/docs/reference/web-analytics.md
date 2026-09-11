%{
  title: "SDK de Análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad subyacente al análisis web de Glossia.",
  category: "Referencia",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Acepta un evento JSON del `@glossia/web` SDK. Siempre responde `202 Accepted`, incluso en dominios desconocidos o cargas malformadas, de modo que el SDK nunca revele qué proyectos recopilan análisis.

El proyecto se resuelve por el dominio del sitio que declara el fragmento. `d` es autoritativo; cuando falta, el servidor recurre al host de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (ej. `example.com`). Obligatorio. |
| `n`   | string | Nombre de evento. Por defecto `pageview`.                          |
| `u`   | string | URL de página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | texto | ID de sesión por pestaña (sessionStorage, borrado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan durante la ingestión y se almacenan en el servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo               | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | GeoIP         | Código ISO 3166-1 alpha-2. Vacío cuando GeoIP no está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de página      | Anfitrión en minúsculas.                                                    |
| `pathname`        | URL de página      | Componente de ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, principal `www.`/`m.` eliminado.                        |
| `browser_language`| Idiomas     | Idioma normalizado de mayor preferencia (ej. `pt-BR`".                    |
| `served_locale`   | Calculado      | Primera meta soportada que coincide con un idioma preferido, de lo contrario vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un idioma que el proyecto no sirve. |

## Modelo de privacidad

- **Sin almacenamiento del lado del cliente.** El SDK no establece cookies y solo almacena un id de sesión por pestaña en `sessionStorage`, lo que el navegador borra al cerrar.
- **Sin identificación por huellas.** No se recopilan huellas de Canvas, WebGL, fuentes y audio. El hash del servidor rotado diariamente proporciona identificadores únicos sin ellas.
- **No se persisten identificadores crudos.** La IP y el User-Agent se leen una vez, se convierten en un hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera identificadores de visitante no relacionados, por lo que los visitantes no se pueden rastrear entre clientes de Glossia.