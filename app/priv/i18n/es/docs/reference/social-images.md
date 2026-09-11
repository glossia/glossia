%{
  title: "Imágenes sociales",
  summary:
    "Vistas previas del tablero diario, renderizado del navegador, almacenamiento y límites de tráfico.",
  category: "referencia",
  order: 30
}
---
Las páginas del Dashboard anuncian una imagen de 1200 × 630 a través de [Open Graph](https://ogp.me/)
y metadatos de imágenes grandes de Twitter. Los proyectos públicos incluyen su nombre, sección,
y el logotipo cargado. Las cuentas públicas reciben una vista previa específica de la sección. Privadas
cuentas y la configuración personal usan una marca genérica de Glossia.

## Identidad y duración de la imagen

El digest de la imagen incluye el contenido mostrado, la revisión del logotipo del proyecto, la plantilla,
estilos, fuentes, activo de marca, archivo de bloqueo de dependencias, y el día actual en
[Tiempo Universal Coordinado](https://www.timeanddate.com/time/aboututc.html).
Cambiar cualquiera de estos crea una nueva dirección. Ordenar los atributos y firmar
a medianoche mantiene la dirección completa estable durante todo el día.

La carga útil firmada no puede ser cambiada por un visitante. Es válida por dos días,
pero solo la carga útil del día actual puede generar una imagen faltante. De ayer,
las imágenes almacenadas permanecen legibles. Los parámetros de consulta nunca se convierten en claves de almacén de objetos.

Las imágenes exitosas se persisten bajo `og/images/<digest>.jpg` en el configurado
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible con el almacén.
Solo una respuesta explícita de objeto-inexistente inicia la generación. Fallos del almacenamiento.
devuelve un error temporal no guardable en caché, sin iniciar Chrome. Una subida debe
tener éxito antes de que una imagen renderizada sea servida.

## Renderizado y límites

Renderizado utiliza Carta con BrowseChrome, la misma pila que el renderizador de imágenes de Tuist.
La piscina supervisada contiene dos navegadores. Cada renderizado tiene un límite de 15 segundos;
cada instancia de aplicación permite como máximo doce nuevos renderizados por minuto.
Las solicitudes de imagen almacenada no consumen ese cupo.

Cachex combina solicitudes concurrentes para la misma imagen y conserva hasta 100
imágenes durante cinco minutos. Un bloqueo no bloqueante de PostgreSQL consultivo previene
a las distintas réplicas de la aplicación de renderizar la misma imagen simultáneamente.
Las demás réplicas reciben un error temporal y pueden volver a intentarlo una vez el objeto exista.

La plantilla combina una insignia de sección Noora con el fondo cálido de Glossia, serif
encabezado, acento de degradado y pie de página discreto. Source Serif 4 e Inter están
empaquetados localmente para que las previsualizaciones no dependan de un servicio de fuentes. Fuentes y mapas de bits
los logotipos están incrustados. La política de seguridad del contenido del documento bloquea los scripts y
recursos externos. Los logotipos se cargan solo desde el almacenamiento de avatares de la aplicación
prefijo y están limitados a cinco millones de bytes, coincidiendo con las subidas del proyecto.

## Comportamiento de respuesta

| Resultado | Estado | Comportamiento en caché |
|---|---|---|
| Imagen almacenada o recién persistida | 200 | Pública, un día, inmutable |
| Firma inválida, expirada o alterada | 404 | Sin almacenamiento |
| Imagen de ayer ausente del almacenamiento | 404 | Sin almacenamiento |
| Navegador ocupado, fallo de renderizado o almacenamiento no disponible | 503 | Sin almacenamiento; reintentar después de 60 segundos |
| Límite de solicitudes de origen excedido | 429 | Sin almacenamiento; intervalo de reintentos en la respuesta |

El origen permite treinta solicitudes por minuto por dirección de cliente, incluyendo
solicitudes inválidas.

## Cloudflare

El `social-images-rate-limit.yaml` recurso en el repositorio de infraestructura
coincide con `GET` y `HEAD` solicitudes bajo `/og/`, incluyendo rastreadores verificados. Esto
permite veinte solicitudes por cada diez segundos por dirección de cliente y ubicación de Cloudflare
ubicación. Superar el límite bloquea las solicitudes durante diez segundos. El general
Las reglas de desafío de la página pública excluyen esta ruta para que los rastreadores de imágenes nunca necesiten
resolver un desafío del navegador.

de Cloudflare [comportamiento predeterminado de caché](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
almacena `.jpg` respuestas y respeta los encabezados de caché del origen. Mantenga la consulta firmada
cadena en la clave de caché predeterminada. No aplique una duración de caché de sobrescritura que
almacena respuestas de error o ignora `no-store`. La firma determinista evita
una entrada de caché por solicitud de página.

Despliegue el recurso de infraestructura junto a la aplicación. Asegúrese de que el origen
sea accesible solo a través del ingreso de confianza, ya que las direcciones de clientes transferidas
son aceptadas por el limitador de solicitudes existente. La piscina de navegadores y el presupuesto de renderizado
también limitan los fallos distribuidos y las solicitudes de origen directo.

## Configuración local

Establecer `GLOSSIA_OG_IMAGES=true` para habilitar la piscina de navegadores en desarrollo. Instale
Google Chrome o Chromium, construya los activos con `mix assets.build`, y configura
las variables de entorno de almacenamiento en objetos existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ejecutar `mix ecto.setup` y `mix phx.server`. Con el almacenamiento configurado, las semillas proporcionan
público `dev/glossia` proyecto un logo. Revisa el `og:image` metadatos de un
página del panel para obtener su dirección de imagen firmada.