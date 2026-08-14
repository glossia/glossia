%{
  title: "SDK de analítica",
  summary: "Los campos recopilados, el endpoint de eventos y el modelo de privacidad de la analítica web de Glossia.",
  category: "reference",
  order: 1
}
---
## Endpoint de eventos

`POST /api/analytics/events`

Acepta un evento JSON del SDK `@glossia/web`. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas útiles con formato incorrecto, para que el SDK nunca revele qué proyectos recopilan datos analíticos.

El proyecto se identifica mediante el dominio del sitio declarado por el fragmento. `d` tiene prioridad; cuando no está presente, el servidor utiliza el host de `u` (la URL de la página) y, después, los valores `Origin`/`Referer` de la solicitud.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | cadena | Dominio del sitio que identifica el proyecto (p. ej., `example.com`). Obligatorio. |
| `n`   | cadena | Nombre del evento. El valor predeterminado es `pageview`. |
| `u`   | cadena | URL de la página (`location.href`). |
| `r`   | cadena | Referente (`document.referrer`). |
| `l`   | cadena | Idiomas del navegador (`navigator.languages.join(",")`). |
| `tz`  | cadena | Zona horaria de IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Ancho de la pantalla en píxeles CSS. |
| `sid` | cadena | Identificador de sesión por pestaña (sessionStorage, se elimina al cerrar). |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados por el servidor

Estos campos se calculan durante la ingesta y se almacenan en el servidor. La dirección IP sin procesar y el User-Agent nunca se almacenan.

| Campo             | Fuente        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash de la dirección IP + UA + proyecto que rota a diario. No se puede vincular entre días.  |
| `country_code`    | GeoIP         | Código ISO 3166-1 alfa-2. Vacío cuando GeoIP no está configurado.        |
| `device`          | Agente de usuario    | `desktop`, `mobile`, `tablet`, `bot` o `unknown`.                 |
| `browser`         | Agente de usuario    | `chrome`, `safari`, `firefox`, `edge`, `opera` o `unknown`.       |
| `os`              | Agente de usuario    | `windows`, `macos`, `ios`, `android`, `linux` o `unknown`.        |
| `hostname`        | URL de la página      | Host en minúsculas.                                                    |
| `pathname`        | URL de la página      | Componente de la ruta.                                                     |
| `referrer_source` | Referente      | Host referente, sin los prefijos `www.`/`m.`.                        |
| `browser_language`| Idiomas     | Configuración regional normalizada con mayor preferencia (por ejemplo, `pt-BR`).                    |
| `served_locale`   | Calculado      | Primer destino compatible que coincide con un idioma preferido; de lo contrario, vacío.   |
| `has_locale_gap`  | Calculado      | `1` cuando el visitante prefiere un idioma que el proyecto no ofrece. |

## Modelo de privacidad

- **Sin almacenamiento del lado del cliente.** El SDK no establece cookies y solo almacena un identificador de sesión por pestaña en `sessionStorage`, que el navegador elimina al cerrarla.
- **Sin identificación mediante huellas digitales.** No se recopilan huellas digitales de Canvas, WebGL, fuentes ni audio. El hash del servidor, que rota a diario, permite contabilizar visitantes únicos sin ellas.
- **No se conservan identificadores sin procesar.** La dirección IP y el agente de usuario se leen una vez, se procesan mediante hash con un secreto del servidor y una sal diaria, y después se descartan.
- **Ámbito por proyecto.** El mismo navegador en dos proyectos genera identificadores de visitante no relacionados, por lo que no se puede rastrear a los visitantes entre clientes de Glossia.