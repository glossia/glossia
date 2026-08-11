%{
  title: "Instalar analíticas web",
  summary: "Añada el SDK web de Glossia a su sitio con una línea de HTML o mediante npm y empiece a recopilar señales de localización.",
  category: "how-to",
  order: 1
}
---
Esta guía presupone que tiene un proyecto de Glossia con el dominio del sitio configurado en los ajustes de analítica del proyecto. La recopilación se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta de script

Añada este fragmento a todas las páginas, preferiblemente en `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página posteriores durante la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` utiliza `window.location.hostname` de forma predeterminada cuando se omite, por lo que puede prescindir de este valor en un sitio con un único dominio. Para alojar el punto de conexión de recopilación en su propia infraestructura, añada `data-endpoint="https://collect.your-host.com"`.

## Opción B: npm

Instale el paquete:

```bash
npm install @glossia/web
```

Inicialícelo una vez en el punto de entrada de su aplicación:

```ts
import glossia from "@glossia/web";

glossia.init();
```

El valor de `domain` se obtiene de `window.location.hostname`, por lo que el SDK registra los datos en el proyecto asociado a su sitio. Pase `{ domain: "example.com" }` para sustituirlo, por ejemplo, para enviar eventos desde un origen de preproducción al mismo proyecto que el de producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifique que funciona

1. Abra su sitio en un navegador.
2. Abra la pestaña de red y confirme que una solicitud `POST` a `/api/analytics/events` devuelve `202 Accepted`.
3. En menos de un minuto, la vista de página aparecerá en el panel de analítica de su proyecto.

## Datos recopilados

El navegador envía la URL de la página, la referencia, `navigator.languages`, la zona horaria y el ancho de la pantalla, además de un identificador de sesión por pestaña. El servidor añade el país a partir de GeoIP y calcula la brecha de localización respecto a los idiomas de destino de su proyecto. No se establecen cookies ni se generan huellas digitales.