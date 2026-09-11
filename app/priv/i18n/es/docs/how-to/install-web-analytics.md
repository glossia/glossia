%{
  title: "Instalar análisis web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una línea de HTML o vía npm, y empieza a recopilar señales de localización.",
  category: "Tutorial",
  order: 1
}
---
Esta guía asume que tienes un proyecto de Glossia con su dominio del sitio configurado en la configuración de análisis del proyecto. La colección se identifica por ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Añade este fragmento a cada página, idealmente en la `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página posteriores en la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` por defecto `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de un solo dominio. Para usar un endpoint de colección personalizado, agrega `data-endpoint="https://collect.your-host.com"`.

## Opción B: npm

Instala el paquete:

```bash
npm install @glossia/web
```

Inicializa una vez en tu punto de entrada de la aplicación:

```ts
import glossia from "@glossia/web";

glossia.init();
```

El `domain` se infiere de `window.location.hostname` así que el SDK registra en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribirlo, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que en producción.

Para registrar un evento personalizado, por ejemplo, una inscripción:

```ts
glossia.track("signup");
```

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma una `POST` solicitud a `/api/analytics/events` devuelve `202 Accepted`.
3. En menos de un minuto, la vista de página aparece en el panel de análisis de tu proyecto.

## ¿Qué se recopila?

El navegador envía la URL de la página, el referrer, `navigator.languages`zona horaria, y el ancho de pantalla, más un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización respecto a los idiomas objetivo de su proyecto. No se establecen cookies y no se fingerprintean datos.