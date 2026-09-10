%{
  title: "Imágenes sociales",
  summary:
    "Vistas previas del tablero diario, renderizado del navegador, almacenamiento y límites de tráfico.",
  category: "referencia",
  order: 30
}
---
Las páginas del tablero publican una imagen de 1200 × 630 a través [Open Graph](https://ogp.me/)
y metadatos de imagen grande de Twitter. Los proyectos públicos incluyen su nombre, sección,
y logotipo subido. Las cuentas públicas reciben una vista previa específica de la sección. Privadas
cuentas y ajustes personales usan marca genérica de Glossia.

## Identidad de imagen y duración

El digesto de la imagen incluye el contenido mostrado, la revisión del logotipo del proyecto, la plantilla,
estilos, fuentes, activo de marca, archivo de bloqueo de dependencias, y día actual en
[Hora Universal Coordinada](https://www.timeanddate.com/time/aboututc.html).
Cambiar cualquiera de estos crea una nueva dirección. Ordenar los atributos y firmar
a medianoche mantiene la dirección completa estable durante todo el día.

La carga útil firmada no puede ser modificada por un visitante. Es válida por dos días,
pero solo la carga útil del día actual puede generar una imagen faltante. De ayer
las imágenes almacenadas permanecen legibles. Los parámetros de consulta nunca se convierten en claves del almacén de objetos.

Las imágenes exitosas se persisten bajo `og/images/<digest>.jpg` en la configurada
[Servicio de Almacenamiento Simple de Amazon](https://aws.amazon.com/s3/)-compatible depósito.
Solo una respuesta explícita de objeto ausente inicia la generación. Fallos de almacenamiento
retorna un fallo temporal no almacenable en caché, sin iniciar Chrome. Una carga debe
tener éxito antes de que una imagen recién renderizada sea servida.

## Renderizado y límites

Renderizado usa Carta con BrowseChrome, el mismo stack que el renderizador de imágenes de Tuist.
La piscina supervisada contiene dos navegadores. Cada renderizado tiene un plazo límite de 15 segundos;
cada instancia de la aplicación permite como máximo doce nuevos renderizados por minuto.
Las solicitudes de imágenes almacenadas no consumen ese cupo.

Cachex combina solicitudes concurrentes para la misma imagen y retiene hasta 100
imágenes por cinco minutos. Un bloqueo consultivo no bloqueante de PostgreSQL impide que
diferentes réplicas de la aplicación de renderizar la misma imagen simultáneamente.
Las demás réplicas reciben un fallo temporal y pueden reintentar una vez que el objeto existe.

La plantilla combina una insignia de sección Noora con el fondo cálido de Glossia, serif
encabezado, acento de gradiente y pie de página discreto. Source Serif 4 e Inter son
empaquetados localmente para que las previsualizaciones no dependan de un servicio de fuentes. Fuentes y raster
logotipos están integrados. La política de seguridad de contenido del documento bloquea scripts y
recursos externos. Los logotipos se cargan solo desde el almacenamiento de avatares de la aplicación
prefijo y están limitados a cinco millones de bytes, coincidiendo con las cargas de proyecto.

## Comportamiento de respuesta

| Resultado | Estado | Comportamiento de caché |
|---|---|---|
| Imagen almacenada o recently persistida | 200 | Público, un día, inmutable |
| Firma inválida, caducada o alterada | 404 | Sin almacenamiento |
| Imagen de ayer no encontrada en el almacenamiento | 404 | Sin almacenamiento |
| Navegador ocupado, fallo de renderizado o almacenamiento no disponible | 503 | Sin almacenamiento; reintentar después de 60 segundos |
| Límite de solicitudes del origen excedido | 429 | Sin almacenamiento; intervalo de reintento en la respuesta |

El origen permite treinta solicitudes por minuto por dirección del cliente, incluyendo
solicitudes inválidas.

## Cloudflare

El `social-images-rate-limit.yaml` recurso en el repositorio de infraestructura
coincide `GET` y `HEAD` solicitudes bajo `/og/`, incluyendo las arañas verificadas. El
permite veinte solicitudes por cada diez segundos por dirección del cliente y Cloudflare
ubicación. Superar el límite bloquea solicitudes por diez segundos. El general
Las reglas del desafío de página pública excluyen esta ruta para que los rastreadores de imágenes nunca necesiten
resolver un desafío del navegador.

de Cloudflare [comportamiento de caché predeterminado](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
almacena `.jpg` respuestas y respeta los encabezados de caché del origen. Mantenga la consulta firmada
cadena en la clave de caché predeterminada. No aplique una duración de caché sobrescrita que
almacena respuestas de error o ignora `no-store`. La firma determinista evita
una entrada de caché por cada solicitud de página.

Despliega el recurso de infraestructura junto con la aplicación. Asegúrate de que el origen
es accesible solo a través de la entrada de confianza, ya que las direcciones del cliente reenviadas
son confiables por el limitador de solicitudes existente. El pool de navegadores y el presupuesto de renderizado
también limitan los fallos distribuidos y las solicitudes de origen directo.

## Configuración local

Configurar `GLOSSIA_OG_IMAGES=true` para habilitar el pool de navegadores en desarrollo. Instala
Google Chrome o Chromium, genera activos con `mix assets.build`y configura
las variables de entorno existentes del almacenamiento de objetos:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ejecutar `mix ecto.setup` y `mix phx.server`. Con el almacenamiento configurado, las semillas dan
el público `dev/glossia` proyecto un logo. Revisa los `og:image` metadatos de un
página del panel para obtener su dirección de imagen firmada.