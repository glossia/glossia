%{
  title: "Instalar analítica web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una sola línea de HTML o vía npm, y comienza a recopilar señales de localización.",
  category: "Guías",
  order: 1
}
---
This guía asume que tienes un proyecto de Glossia con su dominio del sitio configurado en los ajustes de análisis del proyecto. La colección se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta de script

Añade este fragmento a cada página, idealmente en la `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página subsiguientes durante la navegación del lado del cliente en las aplicaciones de una sola página. `data-domain` por defecto a `window.location.hostname` si se omite, por lo que puedes omitirlo en un sitio de dominio único. Para utilizar un punto final de colección personalizado, añade `data-endpoint="https://collect.your-host.com"`.

## Opción B: npm

Instalar el paquete:

```bash
npm install @glossia/web
```

Inicialízalo una vez en el punto de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init();
```

El `domain` se infiere de `window.location.hostname` por lo que el SDK registra en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo, para enviar eventos desde un entorno de pruebas al mismo proyecto que en producción.

Para registrar un evento personalizado, por ejemplo, un registro:

```ts
glossia.track("signup");
```

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma una `POST` solicitud a `/api/analytics/events` retorna `202 Accepted`.
3. En menos de un minuto, la vista de página aparece en el panel de análisis de tu proyecto.

## Qué se recopila

El navegador envía la URL de la página, el remitente, `navigator.languages`fuso horario y ancho de pantalla, además de un ID de sesión por pestaña. El servidor agrega el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de tu proyecto. No se establecen cookies y no se extraen huellas digitales.