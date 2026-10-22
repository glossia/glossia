%{
  title: "Imágenes sociales",
  summary:
    "Vistas previas de enlace del panel de control, marca del proyecto, actualizaciones de imágenes y disponibilidad.",
  category: "Referencia",
  section: "analytics",
  order: 30
}
---

Glossia genera imágenes sociales para los enlaces del panel en su servicio alojado.

## Vistas previas de enlace

Las páginas del panel publican una imagen de 1200 × 630 a través de [Open Graph](https://ogp.me/) y los metadatos de imágenes grandes de Twitter. Compartir un enlace en un servicio que lee estos metadatos puede mostrar la vista previa. El servicio de compartición decide cuándo recuperar o actualizarla.

Los proyectos públicos incluyen su nombre, sección y logotipo cargado. Las cuentas públicas reciben una vista previa específica de la sección. Las cuentas privadas y la configuración personal utilizan la marca genérica de Glossia.

## Marca del proyecto

Suba o reemplace el logotipo del proyecto en Glossia para cambiar la marca utilizada en su vista previa pública. Los logotipos están limitados a cinco millones de bytes, igual que las cargas del proyecto.

La información del proyecto privado no se incluye en una vista previa social pública. Una vista previa no concede acceso al panel enlazado.

## Actualizaciones de imágenes

Las direcciones de imagen cambian cuando cambian el contenido visible, el logotipo del proyecto, la versión de imagen diaria o la implementación de renderizado de Glossia. Una imagen exitosa puede ser almacenada en caché durante un día. Los servicios de compartición pueden retener su propia vista previa almacenada, por lo que reemplazar un logotipo no garantiza una actualización inmediata en todas partes.

Glossia gestiona la generación de imágenes, el almacenamiento, las fuentes y el almacenamiento en caché.

## Disponibilidad

| Resultado | Respuesta |
|---|---|
| Imagen disponible | 200 |
| Dirección de imagen inválida o expirada | 404 |
| Imagen temporalmente indisponible | 503, con un retraso de reintento de 60 segundos |
| Límite de solicitudes excedido | 429, con un retraso de reintento en la respuesta |

Si falta una vista previa, abra la página del panel y comparta su enlace actual. Para un error temporal, inténtelo nuevamente después del retraso indicado. Si el problema persiste, contacte con el soporte de Glossia.
