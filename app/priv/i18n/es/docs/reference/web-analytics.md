%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás del análisis web de Glossia.",
  category: "referencia",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

El `POST /api/analytics/events` permanece disponible para compatibilidad. El script alojado deriva `/v1/collect` de su propio origen; las integraciones de paquetes deben establecer `endpoint` explícitamente.

Acepta un evento JSON del SDK `@glossia/web`. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas de datos malformadas, para que el SDK nunca revele qué proyectos recopilan análisis.

El proyecto se resuelve mediante el dominio del sitio declarado en el fragmento. `d` es autoridad; cuando está ausente, el servidor recurre al host de `u` (la URL de la página) y luego a la solicitud `Origin`/`Referer`.

### Cuerpo de solicitud

| Campos | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (por ejemplo `example.com`). Enviado por la biblioteca del navegador; la resolución alternativa se describe anteriormente. |
| `n`   | string | Nombre del evento. Predeterminado `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma de la página actual (`document.documentElement.lang`). Vacío si no está declarado. |
| `al`  | string | Idiomas de traducción separados por comas desde `link[rel="alternate"][hreflang]`, excluyendo `x-default`. |
| `tz`  | string | Fuso horario IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, eliminado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Campos derivados del servidor

Estos se calculan en la ingesta y se almacenan del lado del servidor. La IP cruda y User-Agent nunca se almacenan.

| Campo             | Origen        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No es vinculable entre días.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 de una cabecera `CF-IPCountry` de confianza o del adaptador de geolocalización IP configurado. Vacío cuando ninguno resuelve un país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` o `unknown`.        |
| `hostname`        | URL de la página      | Host en minúsculas.                                                    |
| `pathname`        | URL de la página      | Componente de la ruta.                                                     |
| `referrer_source` | Referente      | Host del referente, eliminada la parte inicial `www.`/`m.`.                        |
| `browser_language`| Idiomas     | La localización preferida (ej. `pt-BR`).                    |
| `served_locale`   | Idioma de página | Normalizado `sl`, o vacío (mostrado como No reportado) si no fue recopilado. |
| `has_locale_gap`  | Calculado      | `1` cuando ninguna de las preferencias de idioma del visitante coincide con los objetivos del proyecto, las traducciones anunciadas (`al`) o el idioma de la página (`sl`). Las preferencias faltantes no cuentan como una brecha. |

### Resolución de IP del cliente

Para solicitudes desde un par de entrada privado, Glossia utiliza la cabecera `X-Real-IP` sobrescrita de nginx, no la primera entrada controlada por el servidor en `X-Forwarded-For`. Las conexiones públicas directas utilizan la dirección del socket. En Hetzner, tanto el balanceador de carga como nginx deben habilitar el protocolo PROXY para que nginx reciba la dirección del visitante en lugar de la dirección del balanceador. Otros proxies inversos también deben sobrescribir `X-Real-IP` utilizando una fuente autenticada, no una cabecera `X-Forwarded-For` inbound sin restricciones. La política de cabecera reenviada de la configuración genérica por sí sola no garantiza esto. Los pares privados son infraestructura de confianza, por lo que restrinja el acceso directo a los pods.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` sobrescriba la dirección canónica para las solicitudes de un par de entrada privado. Está **desactivado por defecto**, independientemente de la confianza en la cabecera de país. Habilítese solo después de que el borde autentique Cloudflare o elimine cabeceras falsificadas en solicitudes que omiten Cloudflare. Los despliegues DNS-puros deben dejarlo desactivado. Esta dirección define los límites de tasa de IP y la hash diaria de visitantes.

### Resolución de país

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita la ruta rápida de `CF-IPCountry`. Está **desactivado por defecto**. Habilítese solo después de que el origen autentique Cloudflare, rechace solicitudes que omiten Cloudflare, o el ingreso elimine copias no confiables de la cabecera. La configuración de Geolocalización IP de Cloudflare también debe estar habilitada para la zona. `CF-Connecting-IP`, `CF-Ray` y `use-forwarded-headers` no autentican una solicitud por sí solos.

Cuando se habilita la confianza en el encabezado, se usa un código ISO de país válido inmediatamente, sin búsqueda de IP o acceso a la caché. El valor actual del borde siempre tiene precedencia sobre cualquier búsqueda en caché. Códigos faltantes, duplicados, malformados o desconocidos, incluidos los valores `XX` (desconocido) y `T1` (Tor) de Cloudflare, recurren al adaptador de geolocalización configurado.

Sin una base de datos configurada de MaxMind, las búsquedas de respaldo utilizan `api.ipapi.is` y luego `api.country.is` cuando la solicitud principal falla o no retorna ningún país reconocido. Cada solicitud tiene un tiempo de espera de conexión y respuesta de un segundo, con reintentos desactivados. Los resultados exitosos de cualquier proveedor se almacenan en Cachex durante 24 horas, con un límite de tamaño programado de 100,000 entradas y reasignación automática de expiración. `Cachex.fetch/3` colapsa los rechazos concurrentes para la misma IP en un solo resolutor. Los fallos no se almacenan. Las direcciones privadas y reservadas no se envían a ninguno de los proveedores.

### Idioma de página faltante

El panel de control muestra **No reportado** cuando un evento no tiene `sl`. Esto incluye eventos recopilados por versiones antiguas de rastreadores y páginas sin el atributo HTML `lang`. El idioma de la página no se infiere de las preferencias del navegador o la URL. Los eventos históricos conservan los metadatos recopilados en ese momento; las nuevas versiones de rastreadores no las rellenan.

## Modelo de privacidad

- **No hay identificador persistente entre sesiones.** El SDK no establece cookies y almacena solo un ID de sesión por pestaña en `sessionStorage`, que el navegador elimina al cerrar.
- **Sin rastreo por huellas.** Las huellas de Canvas, WebGL, tipo de letra y audio no se recopilan. El hash del servidor rotado diariamente proporciona unicidad sin ellas.
- **No se persisten identificadores crudos.** La IP y User-Agent se leen una vez, se hash con un secreto del servidor y un sal diario, luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos da como resultado IDs de visitante no relacionados, por lo que los visitantes no pueden ser rastreados entre clientes de Glossia.
