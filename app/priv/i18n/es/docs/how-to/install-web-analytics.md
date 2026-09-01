%{
  title: "Instalar análisis web",
  summary:
    "Añada el SDK web de Glossia a su sitio con una línea de HTML o vía npm, y comience a recopilar señales de localización.",
  category: "Tutoriales",
  order: 1
}
---
Esta guía asume que tienes un proyecto de Glossia con su dominio de sitio configurado en los ajustes de análisis del proyecto. La recopilación se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Añade este fragmento a cada página, idealmente en el `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página subsiguientes en la navegación del lado del cliente en las aplicaciones de una sola página. `data-domain` tiene por defecto `window.location.hostname` si se omite, por lo que puedes omitirlo en un sitio de un solo dominio. Para usar un punto final de recopilación personalizado, agrega `data-endpoint="https://collect.your-host.com"`.

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

El `domain` se infiere de `window.location.hostname` de modo que el SDK registra los datos en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo, para enviar eventos desde un origen de pruebas al mismo proyecto que para producción.

Para registrar un evento personalizado, por ejemplo una inscripción:

```ts
glossia.track("signup");
```

## Verifica que funcione

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` a `/api/analytics/events` devuelve `202 Accepted`.
3. En menos de un minuto, la vista de página aparece en el panel de análisis de tu proyecto.

## Lo que se recopila

El navegador envía la URL de la página, el remitente, `navigator.languages`, la zona horaria, el ancho de pantalla y un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de tu proyecto. No se establecen cookies y no se genera ninguna huella digital.