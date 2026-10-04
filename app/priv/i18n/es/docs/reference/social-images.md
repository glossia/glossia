%{
  title: "Imágenes sociales",
  summary:
    "Vistas previas del panel de control, marca del proyecto, actualizaciones de imágenes y disponibilidad.",
  category: "Referencia",
  section: "analytics",
  order: 30
}
---
Glossia genera imágenes sociales para los enlaces del panel de control en su servicio alojado.

## Vistas previas de enlace

Las páginas del panel de control anuncian una imagen de 1200 × 630 a través [Open Graph](https://ogp.me/) y metadatos de imagen grande de Twitter. Compartir un enlace en un servicio que lea estos metadatos puede mostrar la vista previa. El servicio de compartir decide cuándo obtenerla o recargarla.

Los proyectos públicos incluyen su nombre, sección y logotipo cargado. Las cuentas públicas reciben una vista previa específica de la sección. Las cuentas privadas y los ajustes personales usan una marca genérica de Glossia.

## Marca del proyecto

Suba o reemplace el logotipo del proyecto en Glossia para cambiar la marca usada en su vista previa pública. Los logotipos están limitados a cinco millones de bytes, al igual que las cargas del proyecto.

La información privada del proyecto no se incluye en una vista previa pública de imagen social. Una vista previa no otorga acceso a la página del panel vinculada.

## Actualizaciones de imagen

Las direcciones de las imágenes cambian cuando el contenido visualizado, el logotipo del proyecto, la versión de la imagen diaria o la implementación de renderizado de Glossia cambian. Una imagen exitosa puede almacenarse en caché durante un día. Los servicios de compartición pueden mantener su propia vista previa en caché, por lo que reemplazar un logotipo no garantiza una actualización inmediata en todas partes.

Glossia gestiona la generación de imágenes, el almacenamiento, las fuentes y la caché.

## Disponibilidad

| Resultado | Respuesta |
|---|---|
| Imagen disponible | 200 |
| Dirección de imagen inválida o caducada | 404 |
| Imagen temporalmente no disponible | 503, con un retraso de reintento de 60 segundos |
| Límite de solicitudes excedido | 429, con un retraso de reintento en la respuesta |

Si falta la previsualización, abra la página del panel de control y comparta su enlace actual. Para un error temporal, reintente después del retraso indicado. Si el problema persiste, contacte al soporte de Glossia.