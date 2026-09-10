%{
  title: "Instalar analítica web",
  summary:
    "Agregue el SDK web de Glossia a su sitio con una línea de HTML o vía npm, y comience a recopilar señales de localización.",
  category: "Tutorial",
  order: 1
}
---
Esta guía asume que tienes un proyecto de Glossia con su dominio de sitio configurado en la configuración de análisis del proyecto. La recopilación se identifica por ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Añade este fragmento a cada página, idealmente en el `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página subsiguientes a la navegación en el lado del cliente en las aplicaciones de una sola página. `data-domain` por defecto a `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de dominio único. Para usar un endpoint de recopilación personalizado, añade `data-endpoint="https://collect.your-host.com"`.

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

El `domain` se infiere de `window.location.hostname` por lo que el SDK registra en el proyecto registrado para tu sitio. Pasar `{ domain: "example.com" }` para sobrescribir, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de redes y confirma una `POST` solicitud a `/api/analytics/events` devuelve `202 Accepted`.
3. Dentro de un minuto, la vista de página aparece en el panel de análisis de tu proyecto.

## Qué se recopila

El navegador envía la URL de la página, el referente, `navigator.languages`, zona horaria, y ancho de pantalla, además de un identificador de sesión por pestaña. El servidor añade el país (de GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de su proyecto. No se establecen cookies y no se generan huellas.