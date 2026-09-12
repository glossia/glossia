%{
  title: "Instala la analítica web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una línea de HTML o mediante npm, y empieza a recopilar señales de localización.",
  category: "Tutoriales",
  order: 1
}
---
Esta guía asume que tiene un proyecto de Glossia con su dominio del sitio configurado en la configuración de análisis del proyecto. La colección se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta de script

Añada este fragmento a cada página, idealmente en el `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una visualización de página al cargar y registra las visualizaciones de página subsiguientes en la navegación del lado del cliente en las aplicaciones de una sola página. `data-domain` es por defecto `window.location.hostname` si se omite, por lo que puede utilizarlo en un sitio de un solo dominio. Para usar un punto final personalizado de colección, añada `data-endpoint="https://collect.your-host.com"`.

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

El `domain` se infiere de `window.location.hostname` para que el SDK registre en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que en producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma una `POST` solicitud a `/api/analytics/events` devuelve `202 Accepted`.
3. En menos de un minuto, la vista de página aparece en el panel de analíticas de tu proyecto.

## Qué se recopila

El navegador envía la URL de la página, el remitente, `navigator.languages`, la zona horaria y el ancho de pantalla, además de un id de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de tu proyecto. No se establecen cookies y no se registra ninguna huella digital.