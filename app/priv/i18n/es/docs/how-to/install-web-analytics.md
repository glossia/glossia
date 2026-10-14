%{
  title: "Instalar analítica web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una sola línea de HTML o vía npm, y comienza a recopilar señales de localización.",
  category: "Guía",
  section: "analytics",
  order: 1
}
---

Esta guía asume que tienes un proyecto de Glossia con el dominio de su sitio configurado en las configuraciones de analítica del proyecto. La recopilación se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Agrega este fragmento a cada página, idealmente en el `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra vistas subsiguientes a la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` predetermina a `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de un solo dominio. Para usar un punto de recopilación personalizado, agrega `data-endpoint="https://collect.your-host.com"`.

Si tu sitio utiliza una directiva de seguridad de contenido, permite `https://glossia.ai` en ambas `script-src` (o `script-src-elem` cuando esté presente) y `connect-src`. El script se carga desde `/assets/glossia-web.js` y envía eventos a `/v1/collect` en el mismo origen.

## Opción B: npm

Instala el paquete:

```bash
npm install @glossia/web
```

Inicialízalo una vez en el point de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Configura el punto de recopilación de forma explícita al usar el paquete en tu propio paquete, ya que no hay una dirección de script alojada desde la cual inferirlo.

`domain` se infiere de `window.location.hostname` para que el SDK registre en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribir, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que producción.

Para registrar un evento personalizado, por ejemplo, una suscripción:

```ts
glossia.track("signup");
```

## Verifica tu dominio

En la **Configuración de analítica** de tu proyecto, guarda el dominio de tu sitio. La tarjeta **Verificar la propiedad del dominio** muestra el nombre exacto del registro y el valor para tu proyecto. Agrega un registro de texto con tu proveedor de dominio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nombre | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utiliza el dominio y el token mostrados en tu configuración. Algunos proveedores añaden el dominio automáticamente; en ese caso introduce solo `_glossia-verify` como nombre. Después de publicar el registro, haz clic en **Verificar dominio**. Los cambios pueden tardar en estar disponibles, así que vuelve a intentarlo si el registro no se encuentra de inmediato.

Si no puedes editar tus registros de dominio, desliza **Alternativa: verificar con una etiqueta meta del encabezado del sitio**. Copia la etiqueta generada en el `<head>` de tu página de inicio y publícala:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Ambos métodos demuestran el control sobre el dominio configurado. Glossia comprueba el registro de ese dominio o el encabezado del sitio, por lo que copiar el token en otro sitio web no verifica la propiedad. El token es prueba pública, no una contraseña.

Una vez que el dominio está verificado, Glossia registra eventos desde tu fragmento de seguimiento. El fragmento por sí solo no verifica la propiedad. Cambiar el dominio configurado requiere verificación nuevamente.

## Verifica que funcione

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` al `https://glossia.ai/v1/collect` retorna `202 Accepted`.
3. Después de la recopilación y el procesamiento, la vista de página aparece bajo **Analítica** en el panel de control de tu proyecto. Las traducciones que se ejecutan en la página de Visión general están separadas del tráfico del sitio.

Una respuesta `202 Accepted` confirma que la solicitud llegó al recopilador. Los dominios desconocidos o no verificados también se aceptan pero no registran eventos, por lo que confirma que el dominio configurado está verificado en las configuraciones de analítica del proyecto.

## Qué se recopila

El navegador envía la URL de la página, el referente, `navigator.languages`, la zona horaria y el ancho de la pantalla, además de un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de tu proyecto. No se establecen cookies y no se fingerprintea nada.
