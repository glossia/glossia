%{
  title: "Imágenes sociales",
  summary:
    "Previsualizaciones de enlaces del panel, marca del proyecto, actualizaciones de imágenes y disponibilidad.",
  category: "Referencia",
  section: "analytics",
  order: 30
}
---

Glossia genera imágenes sociales para los enlaces del tablero en su servicio alojado.

## Vistas previas de enlace

Las páginas del tablero anuncian una imagen de 1200 × 630 a través de [Open Graph](https://ogp.me/) y metadatos de grandes imágenes de Twitter. Compartir un enlace en un servicio que lee estos metadatos puede mostrar la vista previa. El servicio de compartir decide cuándo recuperarla o actualizarla.

Los proyectos públicos incluyen su nombre, sección y logo subido. Las cuentas públicas reciben una vista previa específica de la sección. Las cuentas privadas y los ajustes personales utilizan la marca genérica de Glossia.

## Marca del proyecto

Suba o reemplace el logo del proyecto en Glossia para cambiar la marca utilizada en su vista previa pública. Los logos están limitados a cinco millones de bytes, igual que las cargas de proyecto.

La información del proyecto privado no se incluye en una vista previa de imagen social pública. Una vista previa no otorga acceso a la página del tablero vinculada.

## Actualizaciones de imagen

Las direcciones de las imágenes cambian cuando se modifica el contenido mostrado, el logo del proyecto, la versión diaria de la imagen o la implementación de renderizado de Glossia. Una imagen generada con éxito puede almacenarse en caché durante un día. Los servicios de compartir pueden conservar su propia vista previa en caché, por lo que reemplazar un logo no garantiza una actualización inmediata en todos los lugares.

Glossia gestiona la generación de imágenes, el almacenamiento, las fuentes y la caché.

## Disponibilidad

| Resultado | Respuesta |
|---|---|
| Imagen disponible | 200 |
| Dirección de imagen inválida o expirada | 404 |
| Imagen temporalmente no disponible | 503, con un retraso de reintento de 60 segundos |
| Límite de solicitudes superado | 429, con un retraso de reintento en la respuesta |

Si falta una vista previa, abra la página del tablero y comparta su enlace actual. Para un error temporal, vuelva a intentarlo después del retraso indicado. Si el problema persiste, contacte el soporte de Glossia.
