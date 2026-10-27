%{
  title: "SDK de análisis",
  summary:
    "Los campos recopilados, el endpoint de eventos y el modelo de privacidad detrás del análisis web de Glossia.",
  category: "Referencia",
  section: "analytics",
  order: 1
}
---

## Endpoint de eventos

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` sigue disponible para compatibilidad. El guion alojado deriva `/v1/collect` de su propio origen; las integraciones del paquete deben establecer `endpoint` explícitamente.

Acepta un evento JSON del SDK `@glossia/web`. Siempre responde `202 Accepted`, incluso para dominios desconocidos o cargas malformadas, de modo que el SDK nunca revela qué proyectos recopilan análisis.

El proyecto se resuelve según el dominio del sitio que declara el fragmento. `d` es determinante; cuando falta, el servidor cae en el anfitrión de `u` (la URL de la página) y luego la solicitud `Origin`/`Referer`.

### Cuerpo de la solicitud

| Campo | Tipo   | Descripción                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Dominio del sitio que identifica el proyecto (p. ej. `example.com`). Enviado por la librería del navegador; la resolución alternativa se describe arriba. |
| `n`   | string | Nombre del evento. Por defecto es `pageview`.                          |
| `u`   | string | URL de la página (`location.href`).                                  |
| `r`   | string | Referente (`document.referrer`).                              |
| `l`   | string | Idiomas del navegador (`navigator.languages.join(",")`).         |
| `sl`  | string | Idioma real de la página (`document.documentElement.lang`). Vacío si no está declarado. |
| `al`  | string | Idiomas de traducción separados por comas procedentes de `link[rel="alternate"][hreflang]`, excluyendo `x-default`. |
| `cl`  | string | Idioma elegido explícitamente, o vacío cuando no se observa una selección. El SDK normaliza las etiquetas BCP 47 y limita la entrada a 64 caracteres. |
| `tz`  | string | Zona horaria IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | número | Ancho de pantalla en píxeles CSS.                                  |
| `sid` | string | ID de sesión por pestaña (sessionStorage, limpiado al cerrar).       |

CORS está abierto (`Access-Control-Allow-Origin: *`) porque el endpoint no acepta credenciales.

## Selección de idioma explícita

`selectLanguage(language)` está disponible como una exportación nombrada, en la exportación predeterminada del SDK y en el objeto global `glossia` del guion alojado. Llámalo después de la inicialización desde un manejador de acción de usuario, antes de la navegación. Las etiquetas de idioma no válidas y las llamadas antes de la inicialización son ignoradas.

El método envía un evento `language_selection` inmediatamente. Su `sl` aún describe la página actual, no el destino. Los eventos subsiguientes incluyen la elección en `cl` hasta que otra elección explícita la reemplace. Sin ninguna selección observada, `cl` está vacío. La elección se almacena como `__glossia_selected_language` en almacenamiento de sesión por pestaña de mismo origen `sessionStorage`; cuando el almacenamiento falla, se mantiene solo en memoria hasta el descargo.

Para los enlaces, `data-glossia-language="zh-Hans"` habilita el seguimiento delegado de los clics primarios de confianza, no modificados, incluida la activación mediante teclado. Los clics programados, los clics ya cancelados, las descargas, los enlaces cruzados y los enlaces dirigidos a otra pestaña o marco son ignorados. El observador se ejecuta en la fase de captura antes de que los enrutadores naveguen, no impide la navegación y también maneja los enlaces insertados dinámicamente. Use ya sea la anotación o la API para una acción, no ambas.

Esto es una señal de intención informada por el cliente, no una prueba de que la navegación tuvo éxito. Los cambios de URL, redirecciones y cambios de idioma HTML no se interpretan como elecciones. La selección no sobrescribe `l` ni `sl`. Una selección válida tiene prevalencia sobre las preferencias del navegador solo al calcular `has_locale_gap`: el idioma elegido debe coincidirse con el destino de proyecto, una traducción anunciada (`al`) o el idioma real de la página (`sl`). La elección en sí misma no es evidencia de disponibilidad. El emparejamiento usa coincidencias exactas o de idioma base, como lo hace con las preferencias del navegador.

Por ejemplo, un visitante que prefiere el japonés que elige explícitamente una traducción disponible en inglés no tiene brecha. Un visitante que prefiere el inglés que elige japonés no disponible sigue teniendo una brecha, incluso en una página en inglés. Un evento de selección emitido antes de la navegación conserva el `sl` de la página actual; el idioma de destino puede reconocerse a través de los objetivos del proyecto o `al` sin asumir que la navegación tuvo éxito.

Las elecciones faltantes, malformadas o de tamaño excesivo regresan a las preferencias del navegador. Si ni una elección ni preferencias del navegador son conocidas, no hay brecha. Los totales y las insignias del panel de control leen la bandera almacenada por evento. Las banderas históricas, incluidas las recopiladas antes de que las elecciones afectaran el cálculo de brecha, no se recalculan: las traducciones anunciadas históricas y las preferencias completas del navegador no se almacenan.

## Campos derivados del servidor

Estos se calculan en la ingesta y se almacenan en el lado del servidor. La IP cruda y el User-Agent nunca se almacenan.

| Campo             | Fuente        | Descripción                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash rotado diariamente de IP + UA + proyecto. No vinculable a través de días.  |
| `country_code`    | Cloudflare / GeoIP | Código ISO 3166-1 alpha-2 desde una cabecera `CF-IPCountry` de confianza, o el adaptador de geolocalización IP configurado. Vacío si ninguno resuelve un país. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` o `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` o `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` o `unknown`.        |
| `hostname`        | URL de página      | Host en minúsculas.                                                    |
| `pathname`        | URL de página      | Componente de ruta.                                                     |
| `referrer_source` | Referidor      | Host del referidor, con `www.`/`m.` inicial eliminado.                        |
| `browser_language`| Idiomas     | Idioma preferido normalizado (por ejemplo, `pt-BR`).                    |
| `served_locale`   | Idioma de página | Normalizado `sl`, o vacío si no fue recopilado. Las filas con un idioma de página vacío se omiten del desglose del idioma del navegador. |
| `selected_locale` | Elección explícita | Normalizado `cl`, o vacío por entrada faltante, malformada o de tamaño excesivo. Almacenado por separado de la preferencia del navegador y el idioma de página. |
| `has_locale_gap`  | Calculado      | `1` cuando una elección explícita válida no tiene coincidencia entre los objetivos del proyecto, las traducciones anunciadas (`al`) o el idioma de página (`sl`). Sin una elección válida, `1` solo cuando las preferencias del navegador no están vacías y ninguna coincide. |

### Resolución de IP del cliente

Para solicitudes desde un par de entrada interno privado, Glossia usa la cabecera `X-Real-IP` sobreescrita de nginx, no la entrada controlada por el llamador en `X-Forwarded-For`. Las conexiones públicas directas usan la dirección del socket. En Hetzner, tanto el equilibrador de carga como nginx deben habilitar el protocolo PROXY para que nginx reciba la dirección del visitante en lugar de la del equilibrador de carga. Otros proxies inversos también deben sobrescribir `X-Real-IP` usando una fuente autenticada, no una cabecera `X-Forwarded-For` entrante sin restricciones. La política de cabecera reenviada del gráfico genérico por sí sola no garantiza esto. Los pares internos son infraestructura de confianza, por lo que restringe el acceso directo al contenedor.

El `GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permite que `CF-Connecting-IP` reemplace la dirección canónica para solicitudes desde un par de entrada interno privado. Está **desactivado por defecto**, independientemente de la confianza en la cabecera de país. Habilítelo solo después de que el borde autentique Cloudflare o elimine cabeceras falsificadas en solicitudes que evadan Cloudflare. Los despliegues de solo DNS deberían dejarlo deshabilitado. Esta dirección también gestiona los límites de tasa de IP y el hash de visitante diario.

### Resolución de país

El `GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` habilita la ruta rápida de `CF-IPCountry`. Está **desactivado por defecto**. Habilítelo solo después de que el origen autentique Cloudflare, rechace solicitudes que evadan Cloudflare, o la entrada elimine copias no confiables de la cabecera. La configuración de Geolocalización IP de Cloudflare también debe habilitarse para la zona. `CF-Connecting-IP`, `CF-Ray` y `use-forwarded-headers` de nginx no autentican una solicitud por sí solos.

Cuando la confianza de cabecera está habilitada, se usa inmediatamente un único código ISO de país válido, sin búsqueda IP ni acceso a caché. El valor actual del borde siempre tiene prioridad sobre cualquier consulta en caché. Los códigos ausentes, duplicados, malformados o desconocidos, incluidos los valores `XX` (desconocido) y `T1` (Tor) de Cloudflare, regresan al adaptador de geolocalización configurado.

Sin una base de datos MaxMind configurada, las consultas de respaldo usan `api.ipapi.is` y luego `api.country.is` si la solicitud principal falla o no devuelve un país reconocido. Cada solicitud tiene un tiempo de espera de conexión y respuesta de un segundo con reintentos deshabilitados. Los resultados exitosos de cualquier proveedor se almacenan en caché por Cachex durante 24 horas, con un límite de tamaño programado de 100,000 entradas y recuperación automática de caducidad. `Cachex.fetch/3` colapsa los fallos concurrentes para la misma IP en un solo resolvedor. Los fallos no se almacenan en caché. Las direcciones privadas y reservadas no se envían a ningún proveedor.

### Idioma de página ausente

El desglose del idioma del navegador omite eventos sin `sl`. Esto incluye eventos recopilados por versiones más antiguas de los rastreadores y páginas sin un atributo HTML `lang`. Estos eventos aún contribuyen al tráfico general. El idioma de la página no se infiere de las preferencias del navegador o la URL. Los eventos históricos conservan los metadatos recopilados en el momento; las nuevas versiones de los rastreadores no los rellenan hacia atrás.

## Modelo de privacidad

- **No identificador persistente de sesión transversal.** El SDK no establece cookies y solo almacena un identificador de sesión por pestaña y un idioma seleccionado explícitamente en `sessionStorage`, que el navegador limpia al cerrar.
- **Sin rastreo de huellas digitales.** Las huellas digitales de Canvas, WebGL, fuentes y audio no se recopilan. El hash del servidor rotado diariamente proporciona identificaciones únicas sin ellas.
- **Sin identificaciones crudas persistentes.** IP y User-Agent se leen una vez, se hash con un secreto del servidor y una sal diaria, y luego se descartan.
- **Alcance por proyecto.** El mismo navegador en dos proyectos genera identificadores de visitantes no relacionados, de modo que los visitantes no pueden ser rastreados entre los clientes de Glossia.
