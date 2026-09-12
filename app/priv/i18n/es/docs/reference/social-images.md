%{
  title: "Imágenes sociales",
  summary:
    "Vistas previas del panel diario, renderizado del navegador, almacenamiento y límites de tráfico.",
  category: "referencia",
  order: 30
}
---
Las páginas del panel de control anuncian una imagen de 1200 × 630 a través de [Open Graph](https://ogp.me/)
y metadatos de imagen grande de Twitter. Los proyectos públicos incluyen su nombre, sección,
y logotipo subido. Las cuentas públicas reciben una vista previa específica de la sección. Privadas
cuentas y ajustes personales utilizan la marca genérica de Glossia.

## Identidad de imagen y vigencia

El digesto de la imagen incluye el contenido mostrado, la revisión del logotipo del proyecto, la plantilla,
estilos, tipografías, activo de marca, archivo de bloqueo de dependencias y día actual en
[Tiempo Universal Coordinado](https://www.timeanddate.com/time/aboututc.html).
Modificar cualquiera de estos crea una nueva dirección. Ordenar los atributos y firmar
a medianoche mantiene la dirección completa estable durante todo el día.

La carga útil firmada no puede ser modificada por un visitante. Es válida durante dos días,
pero solo la carga útil del día actual puede generar una imagen faltante. De ayer
las imágenes almacenadas permanecen legibles. Los parámetros de consulta nunca se convierten en claves de almacenamiento de objetos.

Las imágenes exitosas se guardan bajo `og/images/<digest>.jpg` en el configurado
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible bucket.
Solo una respuesta explícita de objeto ausente inicia la generación. Fallos de almacenamiento
devolver un fallo temporal no almacenable en caché, sin iniciar Chrome. Una subida debe
tener éxito antes de que una imagen generada sea servida.

## Renderizado y límites

El renderizado usa Carta con BrowseChrome, la misma pila que el renderizador de imágenes de Tuist.
La piscina supervisada contiene dos navegadores. Cada renderizado tiene un plazo de 15 segundos;
cada instancia de aplicación permite como máximo doce nuevos renderizados por minuto.
Las solicitudes de imágenes almacenadas no consumen esa cuota.

Cachex combina solicitudes concurrentes para la misma imagen y retiene hasta 100
imágenes durante cinco minutos. Un bloqueo consultivo no bloqueante de PostgreSQL previene
diferentes réplicas de aplicación de renderizar la misma imagen simultáneamente.
Las demás réplicas reciben un fallo temporal y pueden reintentar una vez que el objeto existe.

La plantilla empareja una insignia de sección Noora con el fondo cálido de Glossia, serif
cabecera, acento de degradado y pie de página sobrio. Source Serif 4 e Inter están
empaquetados localmente para que las vistas previas no dependan de un servicio de fuentes. Fuentes y Raster
los logos están integrados. La política de seguridad de contenido del documento bloquea scripts y
recursos externos. Los logos se cargan solo desde el almacenamiento de avatares de la aplicación
prefijo y están limitados a cinco millones de bytes, coincidiendo con las cargas de los proyectos.

## Comportamiento de respuesta

| Resultado | Estado | Comportamiento de caché |
|---|---|---|
| Imagen almacenada o recién persistida | 200 | Público, un día, inmutable |
| Firma inválida, caducada o alterada | 404 | Sin almacenamiento |
| Imagen de ayer faltante en el almacenamiento | 404 | Sin almacenamiento |
| Navegador ocupado, error de renderizado o almacenamiento no disponible | 503 | Sin almacenamiento; reintente después de 60 segundos |
| Límite de solicitudes de origen excedido | 429 | Sin almacenamiento; intervalo de reintento en la respuesta |

El origen permite treinta solicitudes por minuto por dirección de cliente, incluyendo
solicitudes inválidas.

## Cloudflare

El `social-images-rate-limit.yaml` recurso en el repositorio de infraestructura
concuerda con `GET` y `HEAD` solicitudes bajo `/og/`, incluidos los crawlers verificados. Esto
permite veinte solicitudes por cada diez segundos por dirección del cliente y Cloudflare
ubicación. Exceder el límite bloquea las solicitudes por diez segundos. El general
las reglas del desafío de página pública excluyen esta ruta para que los rastreadores de imágenes nunca necesiten
resolver un desafío del navegador.

de Cloudflare [comportamiento predeterminado de caché](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
almacena `.jpg` respuestas y respeta los encabezados de caché del origen. Mantenga la consulta firmada
cadena en la clave de caché predeterminada. No aplique una duración de caché de sobrescritura que
almacena respuestas de error o ignora `no-store`. La firma determinística evita
una entrada de caché por solicitud de página.

Despliegue el recurso de infraestructura junto con la aplicación. Asegúrese de que el origen
es accesible solo a través del ingreso de confianza, ya que las direcciones del cliente reenviadas
son de confianza por el limitador de solicitudes existente. La piscina de navegadores y el presupuesto de renderizado
también limitaron los fallos distribuidos y las solicitudes de origen directo.

## Configuración local

Establecer `GLOSSIA_OG_IMAGES=true` para habilitar la piscina de navegadores en desarrollo. Instale
Google Chrome o Chromium, construya los activos con `mix assets.build`, y configurar
las variables de entorno existentes de almacenamiento de objetos:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ejecutar `mix ecto.setup` y `mix phx.server`. Con el almacenamiento configurado, las semillas proporcionan
el público `dev/glossia` proyecto un logotipo. Revisar los `og:image` metadatos de un
página del panel de control para obtener su dirección de imagen firmada.