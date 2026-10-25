%{
  title: "Instalar análisis web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una línea de HTML o vía npm, y empieza a recopilar señales de localización.",
  category: "Cómo",
  section: "analytics",
  order: 1
}
---

Esta guía asume que tienes un proyecto de Glossia con su dominio del sitio configurado en la configuración de análisis del proyecto. La recopilación se identifica por ese dominio, por lo que no hay clave ni secreto que copiar.

## Opción A: etiqueta de script

Añade este fragmento a cada página, idealmente en `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página posteriores en la navegación lado del cliente en aplicaciones de una sola página. `data-domain` predetermina `window.location.hostname` cuando se omite, por lo que puedes eliminarlo en un sitio de un solo dominio. Para usar un punto final de recopilación personalizado, añade `data-endpoint="https://collect.your-host.com"`.

Si tu sitio utiliza una política de seguridad de contenido, permite `https://glossia.ai` tanto en `script-src` (o `script-src-elem` cuando esté presente) como en `connect-src`. El script carga desde `/assets/glossia-web.js` y envía eventos a `/v1/collect` en el mismo origen.

## Opción B: npm

Instala el paquete:

```bash
npm install @glossia/web
```

Inicialízalo una vez en el punto de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Define el punto final de recopilación explícitamente al usar el paquete en tu propio bundle, ya que no hay una dirección de script alojada desde la que inferirlo.

`domain` se infiere a partir de `window.location.hostname` por lo que el SDK registra contra el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifica tu dominio

En la **Configuración de análisis** de tu proyecto, guarda el dominio de tu sitio. La tarjeta **Verificar propiedad del dominio** muestra el nombre exacto del registro y el valor para tu proyecto. Agrega un registro de texto con tu proveedor de dominio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nombre | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utiliza el dominio y el token mostrados en tu configuración. Algunos proveedores añaden el dominio automáticamente; en ese caso, introduce solo `_glossia-verify` como el nombre. Después de publicar el registro, haz clic en **Verificar el dominio**. Los cambios pueden tardar tiempo en estar disponibles, así que vuelve a intentarlo si el registro no se encuentra inmediatamente.

Si no puedes editar tus registros de dominio, expande **Alternativa: verifica con una etiqueta meta de página de inicio**. Copia la etiqueta generada en `<head>` de tu página de inicio y publícalo:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Cualquier método demuestra el control sobre el dominio configurado. Glossia verifica el registro o la página de inicio de ese dominio, por lo que copiar el token a otro sitio web no verifica la propiedad. El token es una prueba pública, no una contraseña.

Una vez verificado el dominio, Glossia registra eventos desde tu fragmento de seguimiento. El fragmento por sí solo no verifica la propiedad. Cambiar el dominio configurado requiere verificación nuevamente.

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` a `https://glossia.ai/v1/collect` devuelve `202 Accepted`.
3. Después de la recopilación y el procesamiento, la vista de página aparece bajo **Análisis** en el panel de control de tu proyecto. El procesamiento de traducciones en la página general está separado del tráfico del sitio web.

Una respuesta `202 Accepted` confirma que la solicitud llegó al recolector. Los dominios desconocidos o sin verificar también se aceptan pero no registran eventos, por lo que confirma que el dominio configurado está verificado en la configuración de análisis del proyecto.

## Qué se recopila

El navegador envía la URL de la página, el referrer, `navigator.languages`, la zona horaria y el ancho de pantalla, además de un id de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de tu proyecto. No se establecen cookies y no se genera ninguna huella digital.
