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

Acepta un evento JSON desde el `@glossia/web` SDK. Siempre responde `202 Accepted`, incluyendo para dominios desconocidos o cargas malformadas, por lo que el SDK nunca revela qué proyectos recopilan datos de análisis

El proyecto se resuelve mediante el dominio del sitio que declara el fragmento. `d` es la referencia; cuando falta el servidor recurre al host de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (por ejemplo, `example.com`). Obligatorio. |
| `n`   | string | Nombre de evento. Predeterminado a `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referer (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `tz`  | string | Horario IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                            |
| `sid` | string | ID de sesión por pestaña (sessionStorage, se limpia al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan en la ingestión y se almacenan del lado del servidor. La IP y el User-Agent brutos nunca se almacenan.

| Campo             | Fuente        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash de rotación diaria de IP + UA + proyecto. No enlazable entre días.  |
| `country_code`    | GeoIP         | Código alfa-2 ISO 3166-1. Vacío cuando GeoIP no está configurado.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de la página      | Host en minúsculas.                                                    |
| `pathname`        | URL de la página      | Componente de ruta.                                                     |
| `referrer_source` | Referer      | Host del referer,`www.`/`m.` eliminados.                        |
| `browser_language`| Idiomas     | Localización prefiere normalizada (por ejemplo, `pt-BR`).                    |
| `served_locale`   | Calculado      | Primera meta compatible alineada con un idioma prefiere, de lo contrario vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un idioma que el proyecto no sirve. |

## Modelo de privacidad

- **Almacenamiento sin lado del cliente.** El SDK no establece cookies y almacena únicamente un ID de sesión por pestaña en `sessionStorage`, el cual el navegador elimina al cerrar.
- **Sin identificación por huella.** Las huellas de Canvas, WebGL, fuentes y audio no se recopilan. El hash del servidor rotado diariamente proporciona unicidad sin ellas.
- **No se persisten identificadores brutos.** La IP y el User-Agent se leen una vez, se hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos produce IDs de visitante no relacionados, por lo que los visitantes no pueden rastrearse entre clientes de Glossia.