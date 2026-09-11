%{
  title: "Instalar análisis web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una línea de HTML o vía npm, y comienza a recopilar señales de localización.",
  category: "cómo hacer",
  order: 1
}
---
Esta guía asume que tienes un proyecto de Glossia con su dominio del sitio configurado en la configuración de análisis del proyecto. La colección se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Agregue este fragmento a cada página, idealmente en el `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página subsiguientes durante la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` por defecto en `window.location.hostname` cuando se omite, por lo que puede omitirlo en un sitio de un solo dominio. Para usar un endpoint de colección personalizado, añada `data-endpoint="https://collect.your-host.com"`.

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

El `domain` se infiere de `window.location.hostname` por lo que el SDK registra en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo para enviar eventos desde un entorno de pruebas al mismo proyecto que el de producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifica que funcione

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma una `POST` solicitud a `/api/analytics/events` devuelve `202 Accepted`.
3. En menos de un minuto, la vista de página aparece en el panel de análisis de tu proyecto.

## ¿Qué se recopila?

El navegador envía la URL de la página, el referer, `navigator.languages`, zona horaria, y el ancho de pantalla, además de un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de su proyecto. No se establecen cookies y no se generan huellas digitales.