%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el punto final de eventos y el modelo de privacidad detrás del análisis web de Glossia.",
  category: "Referencia",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Acepta un evento JSON desde el `@glossia/web` SDK. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas malformadas, por lo que el SDK nunca revela qué proyectos recopilan análisis.

El proyecto se resuelve por el dominio del sitio que declara el fragmento. `d` es autoritativo; cuando está ausente, el servidor vuelve al anfitrión de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de solicitud

| Campo | Tipo   | Describección                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (e.g. `example.com`). Obligatorio. |
| `n`   | string | Nombre de evento. Por defecto a `pageview`.                          |
| `u`   | string | URL de página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`)         |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`El documento reensamblado previamente falló la validación: la recuperación de texto literal de Markdown devolvió JSON inválido
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, borrado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan en la ingestión y se almacenan en el servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotativo diario de IP + UA + proyecto. No vinculable entre días.  |
| `country_code`    | GeoIP         | código ISO 3166-1 alpha-2. Vacío cuando GeoIP no está configurado.        |
| `device`          | Agente de usuario    | `desktop`, `mobile`, `tablet`, `bot`, o `unknown`.                 |
| `browser`         | Agente de usuario    | `chrome`, `safari`El documento reensamblado falló la validación previamente: la recuperación de texto literal de Markdown debe devolver un array de cadenas JSON de longitud coincidente. `firefox`, `edge`, `opera`, o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, o `unknown`.        |
| `hostname`        | URL de página      | host en minúsculas.                                                    |
| `pathname`        | URL de página      | componente de ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, principal `www.`/`m.` eliminados.                        |
| `browser_language`| Idiomas     | Idioma preferido normalizado (p.ej. `pt-BR`)
| `served_locale`   | Calculado      | Primer objetivo compatible coincidiendo con un idioma preferido, de lo contrario vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un idioma que el proyecto no atiende. |

## Modelo de privacidad

- **No almacenamiento del lado del cliente.** El SDK no establece cookies y solo almacena un id de sesión en `sessionStorage`, que el navegador borra al cerrar.
- **Sin huella digital.** No se recogen las huellas de Canvas, WebGL, fuentes y audio. El hash del servidor rotado diariamente proporciona identificadores únicos sin ellas.
- **No se persisten identificadores brutos.** La dirección IP y el User-Agent solo se leen una vez, se generan hashes con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera identificadores de visitante no relacionados, por lo que los visitantes no pueden ser rastreados entre clientes de Glossia.