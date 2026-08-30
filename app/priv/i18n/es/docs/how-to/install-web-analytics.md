%{
  title: "Instalar análisis web",
  summary: "Agregue el SDK web de Glossia a su sitio con una línea de HTML o vía npm, y comience a recopilar señales de localización.",
  category: "tutorial",
  order: 1
}
---
Esta guía asume que tienes un proyecto de Glossia con su dominio del sitio configurado en la configuración de análisis del proyecto. La colección se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Agrega este fragmento a cada página, idealmente en el `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargarla y registra las vistas de página subsiguientes durante la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` es por defecto `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de dominio único. Para usar un punto final de colección personalizado, agrega `data-endpoint="https://collect.your-host.com"`.

## Opción B: npm

Instala el paquete:

```bash
npm install @glossia/web
```

Inicialízalo una vez en el punto de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init();
```

El `domain` se infiere a partir de `window.location.hostname`, por lo que el SDK registra datos en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo, para enviar eventos desde un origen de pruebas al mismo proyecto que el de producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifica que funcione

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` a `/api/analytics/events` devuelva `202 Accepted`.
3. Dentro de un minuto, la vista de página aparece en el panel de análisis de tu proyecto.

## Qué se recopila

El navegador envía la URL de la página, el referer, `navigator.languages`, la zona horaria y el ancho de pantalla, además de un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización con respecto a los idiomas objetivo de tu proyecto. No se establecen cookies y no se generan huellas.