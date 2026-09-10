%{
  title: "Imágenes sociales",
  summary:
    "Vistas previas del panel diario, renderizado del navegador, almacenamiento y límites de tráfico.",
  category: "Referencias",
  order: 30
}
---
Las páginas del panel anuncian una imagen de 1200 × 630 a través de [Open Graph](https://ogp.me/)
y metadatos de imagen grande de Twitter. Los proyectos públicos incluyen su nombre, sección,
y el logotipo cargado. Las cuentas públicas reciben una vista previa específica de la sección. Privadas
cuentas y configuraciones personales utilizan la marca genérica de Glossia.

## Identidad de imagen y validez

El resumen de imagen incluye el contenido mostrado, la revisión del logotipo del proyecto, la plantilla,
estilos, fuentes, activo de marca, archivo de bloqueo de dependencias, y el día actual en
[Tiempo Universal Coordinado](https://www.timeanddate.com/time/aboututc.html).
Cualquier cambio en estos crea una nueva dirección. Ordenar los atributos y firmar
a medianoche mantiene la dirección completa estable durante todo el día.

La carga útil firmada no puede ser cambiada por un visitante. Es válida durante dos días,
pero solo la carga útil del día actual puede generar una imagen faltante. De ayer
las imágenes almacenadas siguen siendo legibles. Los parámetros de consulta nunca se convierten en claves de almacén de objetos.

Las imágenes exitosas se persisten bajo `og/images/<digest>.jpg` en el configurado
[Servicio de Almacenamiento Simple de Amazon](https://aws.amazon.com/s3/)-compatible con el almacén.
Solo una respuesta de objeto ausente explícita inicia la generación. Fallos de almacenamiento.
devolver un error temporal no cachable, sin iniciar Chrome. Una subida debe
tener éxito antes de que una imagen recién renderizada se sirva.

## Renderizado y límites

Renderizado usa Carta con BrowseChrome, la misma pila que el renderizador de imágenes de Tuist.
El pool supervisado contiene dos navegadores. Cada renderizado tiene un plazo límite de 15 segundos;
cada instancia de aplicación permite como máximo doce nuevos renderizados por minuto.
Las solicitudes de imágenes almacenadas no consumen tal cuota.

Cachex combina solicitudes concurrentes para la misma imagen y retiene hasta 100
imágenes durante cinco minutos. Un bloqueo de asesoramiento no bloqueante de PostgreSQL evita
a diferentes réplicas de aplicación renderizar la misma imagen simultáneamente.
Las otras réplicas reciben un error temporal y pueden reintentar una vez que el objeto exista.

La plantilla empareja un distintivo de sección Noora con el fondo cálido de Glossia, serif
encabezado, acento de degradado y pie de página sobrio. Source Serif 4 e Inter están
empacados localmente para que las vistas previas no dependan de un servicio de fuentes. Fuentes y raster
logos están incrustados. La política de seguridad de contenido del documento bloquea scripts y
recursos externos. Los logos se cargan solo desde el almacenamiento de avatar de la aplicación
prefijo y se limitan a cinco millones de bytes, coincidiendo con las cargas de proyecto.

## Comportamiento de respuesta

| Resultado | Estado | Comportamiento de caché |
|---|---|---|
| Imagen almacenada o recién persistida | 200 | Pública, un día, inmutable |
| Firma inválida, expirada o alterada | 404 | Sin almacenamiento |
| Imagen de ayer ausente en el almacenamiento | 404 | Sin almacenamiento |
| Navegador ocupado, fallo de renderizado o almacenamiento no disponible | 503 | Sin almacenamiento; reintentar después de 60 segundos |
| Límite de solicitudes del origen excedido | 429 | Sin almacenamiento; intervalo de reintentos en la respuesta |

El origen permite treinta solicitudes por minuto por dirección de cliente, incluyendo
solicitudes inválidas.

## Cloudflare

El `social-images-rate-limit.yaml` recurso en el repositorio de infraestructura
coincide `GET` y `HEAD` solicitudes bajo `/og/`, incluidos los rastreadores verificados. Esto
permite veinte solicitudes por diez segundos por dirección de cliente y Cloudflare
ubicación. Exceder el límite bloquea las solicitudes durante diez segundos. El general
las reglas de desafío de página pública excluyen esta ruta por lo que los rastreadores de imágenes nunca necesitan
resolver un desafío del navegador.

de Cloudflare [comportamiento de caché por defecto](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
almacena `.jpg` respuestas y respeta los encabezados de caché de origen. Mantén la consulta
cadena firmada en la clave de caché por defecto. No apliques una duración de caché que
almacene respuestas de error o ignore. `no-store`. La firma determinista evita
una entrada en caché por solicitud de página.

Despliegue el recurso de infraestructura junto a la aplicación. Asegúrese de que el origen
es alcanzable solo a través del ingreso de confianza, ya que las direcciones de clientes reenviadas
son aceptadas por el limitador de solicitudes existente. La piscina de navegadores y el presupuesto de renderizado
también limitaron los fallos distribuidos y las solicitudes de origen directo.

## Configuración local

Establecer `GLOSSIA_OG_IMAGES=true` para habilitar la piscina de navegadores en desarrollo. Instalar
Google Chrome o Chromium, construya activos con `mix assets.build`, y configurar
las variables de entorno de almacenamiento de objetos existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Ejecutar `mix ecto.setup` y `mix phx.server`. Con el almacenamiento configurado, las semillas proporcionan
el público `dev/glossia` proyecto un logotipo. Revisa el `og:image` metadatos sobre un
página del panel para obtener su dirección de imagen firmada.