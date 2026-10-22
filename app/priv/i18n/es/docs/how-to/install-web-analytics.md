%{
  title: "Instalar análisis web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una línea de HTML o vía npm, y empieza a recopilar señales de localización.",
  category: "tutorial",
  section: "analytics",
  order: 1
}
---

Esta guía asume que tienes un proyecto de Glossia con su dominio del sitio configurado en la configuración de análisis del proyecto. La recopilación se identifica mediante ese dominio, por lo que no hay ninguna clave ni ningún secreto que copiar.

## ## Opción A: etiqueta script

Añade este fragmento a cada página, idealmente en `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página subsiguientes en la navegación a nivel del cliente en las aplicaciones de una sola página. `data-domain` predetermina `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de un solo dominio. Para usar un punto final de recopilación personalizado, añade `data-endpoint="https://collect.your-host.com"`.

Si tu sitio usa una política de seguridad del contenido, permite `https://glossia.ai` en `script-src` (o `script-src-elem` cuando esté presente) y `connect-src`. El script carga desde `/assets/glossia-web.js` y envía eventos a `/v1/collect` en el mismo origen.

## ## Opción B: npm

Instala el paquete:

```bash
npm install @glossia/web
```

InicIALIZÁLO una vez en el punto de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Establece el punto final de recopilación explícitamente cuando uses el paquete en tu propio paquete, ya que no hay ninguna dirección de script alojada desde la que inferirlo.

`domain` se infiere de `window.location.hostname` por lo que el SDK registra en contra del proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo, para enviar eventos desde un origen de pruebas al mismo proyecto que la producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## ## Verifica tu dominio

En tu proyecto, guarda el dominio del sitio en **Configuración de análisis**. La tarjeta **Verificar propiedad del dominio** muestra el nombre del registro y el valor exactos para tu proyecto. Añade un registro de texto con tu proveedor de dominio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nombre | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utiliza el dominio y el token mostrados en tu configuración. Algunos proveedores añaden el dominio automáticamente; en ese caso, introduzca solo `_glossia-verify` como el nombre. Después de publicar el registro, haz clic en **Verificar dominio**. Los cambios pueden tardar en estar disponibles, así que reinténtalo si no se encuentra el registro inmediatamente.

Si no puedes editar tus registros de dominio, expande **Alternativa: verifica con una etiqueta meta en la página de inicio**. Copia la etiqueta generada en `<head>` de la página de inicio de tu sitio y publícala:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Cualquiera de estos métodos prueba el control sobre el dominio configurado. Glossia comprueba el registro o la página de inicio de ese dominio, por lo que copiar el token en otro sitio web no verifica la propiedad. El token es una prueba pública, no una contraseña.

Una vez que el dominio se verifica, Glossia registra eventos desde tu fragmento de seguimiento. El fragmento por sí solo no verifica la propiedad. Cambiar el dominio configurado requiere una verificación nuevamente.

## ## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` al `https://glossia.ai/v1/collect` devuelve `202 Accepted`.
3. Después de la recopilación y el procesamiento, la vista de página aparece en **Análisis** del panel de control de tu proyecto. La traducción que se ejecuta en la página de Descripción general está separada del tráfico del sitio web.

Una respuesta `202 Accepted` confirma que la solicitud llegó al recopilador. Los dominios desconocidos o no verificados también se aceptan pero no registran eventos, por lo que confirma que el dominio configurado se verifiŋ en la configuración de análisis del proyecto.

## ¿Qué se recopila?

El navegador envía la URL de la página, el remitente, `navigator.languages`, la zona horaria y el ancho de pantalla, junto con un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización en relación con los idiomas objetivo de tu proyecto. No se establecen cookies y no se fingerprintea nada.
