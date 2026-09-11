%{
  title: "Imágenes sociales",
  summary:
    "Previsualizaciones del panel diario, renderizado del navegador, almacenamiento y límites de tráfico.",
  category: "Referencia",
  order: 30
}
---
Las páginas del tablero anuncian una imagen de 1200 × 630 a través de [Open Graph](https://ogp.me/)
y los metadatos de gran imagen de Twitter. Los proyectos públicos incluyen su nombre, sección,
y el logotipo subido. Las cuentas públicas reciben una previsualización específica de la sección. Privadas
las cuentas y la configuración personal utilizan su identidad de marca genérica de Glossia.

## Identidad de imagen y vigencia

El digesto de la imagen incluye el contenido mostrado, la revisión del logotipo del proyecto, la plantilla,
estilos, fuentes, activo de marca, archivo de bloqueo de dependencias, y el día actual en
[Hora Universal Coordinada](https://www.timeanddate.com/time/aboututc.html).
Modificar cualquiera de estos crea una nueva dirección. Ordenar los atributos y firmar
a medianoche mantiene la dirección completa estable durante todo el día.

La carga útil firmada no puede ser cambiada por un visitante. Es válida por dos días,
pero solo la carga útil del día actual puede generar una imagen faltante. De ayer
imágenes almacenadas permanecen legibles. Los parámetros de consulta nunca se convierten en claves de almacén de objetos.

Imágenes exitosas se persisten bajo `og/images/<digest>.jpg` en el configurado
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible almacen.
Solo una respuesta de objeto ausente explícita inicia la generación. Fallos de almacenamiento.
devolver un error temporal no cachéable, sin iniciar Chrome. La subida debe
tener éxito antes de que una imagen renderizada sea servida.

## Renderizado y límites

Renderizado utiliza Carta con BrowseChrome, la misma pila que el renderizador de imágenes de Tuist.
El pool supervisado contiene dos navegadores. Cada renderizado tiene un plazo de 15 segundos;
Cada instancia de aplicación permite como máximo doce nuevas renderizaciones por minuto.
Las solicitudes de imágenes almacenadas no consumen ese límite.

Cachex combina solicitudes concurrentes para la misma imagen y retiene hasta 100
imágenes durante cinco minutos. Un bloqueo de advisory de PostgreSQL sin bloqueo impide
que las diferentes réplicas de aplicación se rendericen la misma imagen simultáneamente.
Las otras réplicas reciben un error temporal y pueden reintentar una vez que el objeto exista.

La plantilla empareja una insignia de sección de Noora con el fondo cálido de Glossia, serif
encabezado, acento degradado y pie de página sobrio. Source Serif 4 e Inter son
empaquetados localmente para que las vistas previas no dependan de un servicio de fuentes. Fuentes y raster
logotipos están incrustados. La política de seguridad de contenido del documento bloquea los scripts y
recursos externos. Los logotipos solo se cargan desde el almacenamiento de avatares de la aplicación
prefijo y están limitados a cinco millones de bytes, coincidiendo con las cargas de proyecto.

## Comportamiento de respuesta

| Resultado | Estado | Comportamiento de caché |
|---|---|---|
| Imagen almacenada o recién persistida | 200 | Público, un día, inmutable |
| Firma inválida, expirada o alterada | 404 | Sin almacenamiento |
| Imagen de ayer ausente del almacenamiento | 404 | Sin almacenamiento |
| Navegador ocupado, fallo de renderizado o almacenamiento no disponible | 503 | Sin almacenamiento; reintentar después de 60 segundos |
| Límite de solicitudes al origen excedido | 429 | Sin almacenamiento; intervalo de reintentos en respuesta |

El origen permite treinta solicitudes por minuto por cada dirección de cliente, incluyendo
solicitudes inválidas.

## Cloudflare

El `social-images-rate-limit.yaml` recurso en el repositorio de infraestructura
concuerda con `GET` y `HEAD` solicitudes bajo `/og/`, incluidas las arañas verificadas. Esto
permite veinte solicitudes por cada diez segundos por dirección del cliente y Cloudflare
ubicación. Superar el límite bloquea las solicitudes durante diez segundos. El general
las reglas del desafío de la página pública excluyen esta ruta para que los rastreadores de imágenes nunca necesiten
resolver un desafío del navegador.

de Cloudflare [comportamiento predeterminado del caché](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
almacena `.jpg` respuestas y respeta los encabezados de caché del origen. Mantenga la consulta firmada
cadena en la clave predeterminada del caché. No aplique una duración de caché de sobrescritura que
almacena respuestas de error en caché o ignora `no-store`. La firma determinista evita
una entrada de caché por solicitud de página.

Despliega el recurso de infraestructura junto con la aplicación. Asegúrate de que el origen
sea accesible únicamente a través del punto de entrada confiable, ya que las direcciones de clientes reenviadas
son confiables para el limitador de solicitudes existente. La piscina de navegadores y el presupuesto de renderizado
también limitan los fallos distribuidos y las solicitudes de origen directo.

## Configuración local

Establece `GLOSSIA_OG_IMAGES=true` para activar la piscina de navegadores en desarrollo. Instala
Google Chrome o Chromium, genera los activos con `mix assets.build`, y configura
las variables de entorno de almacenamiento en objetos existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ejecuta `mix ecto.setup` y `mix phx.server`. Con el almacenamiento configurado, las semillas dan
el público `dev/glossia` un logotipo para el proyecto. Inspecciona el `og:image` metadatos sobre un
página del panel de control para obtener su dirección de imagen firmada.