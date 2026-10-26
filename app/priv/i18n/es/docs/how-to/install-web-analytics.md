%{
  title: "Instalar analítica web",
  summary:
    "Añade el SDK web de Glossia a tu sitio con una línea de HTML o vía npm, y comienza a recopilar señales de localización.",
  category: "Guía",
  section: "analytics",
  order: 1
}
---

Esta guía asume que tienes un proyecto Glossia con su dominio del sitio configurado en la configuración analítica del proyecto. La recopilación se identifica por ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta script

Añade este fragmento a cada página, idealmente en `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página subsiguientes en la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` predetermina `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de dominio único. Para usar un punto de recopilación personalizado, añade `data-endpoint="https://collect.your-host.com"`.

Si tu sitio utiliza una directiva de seguridad de contenido, permite `https://glossia.ai` en tanto `script-src` (o `script-src-elem` cuando esté presente) y `connect-src`. El script se carga desde `/assets/glossia-web.js` y envía eventos a `/v1/collect` en el mismo origen.

## Opción B: npm

Instalar el paquete:

```bash
npm install @glossia/web
```

Iniciar el paquete una vez en el punto de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Establecer el punto de recopilación explícitamente al usar el paquete en tu propio paquete de distribución, ya que no hay una dirección de script alojada de la que inferirlo.

`domain` se infiere de `window.location.hostname` de modo que el SDK registre eventos contra el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribirlo, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que la producción.

Para registrar un evento personalizado, por ejemplo, un registro:

```ts
glossia.track("signup");
```

## Trazar elecciones de lenguaje explícito

Para distinguir la elección de un visitante de su preferencia del navegador, llama al SDK en el manejador de acción de usuario del selector de idioma, antes de navegar:

```js
glossia.selectLanguage("zh-Hans");
```

Este método está disponible en el SDK importado tras `glossia.init()` y en el global `glossia` al usar el script alojado.

Alternativamente, anota los enlaces de conmutación de idioma de mismo origen:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Utiliza una integración por acción, no ambas. Los enlaces anotados registran la activación genuina del usuario, incluida la activación por teclado. Ignoran los clics con guiones de script, descargas, clics modificados, destinos de origen cruzado y enlaces que abren otra pestaña o marco, sin bloquear la navegación.

El SDK envía inmediatamente un evento `language_selection` e incluye el lenguaje elegido (`cl`) en los eventos subsiguientes. La elección se almacena en `sessionStorage` para la pestaña y el origen actuales hasta que otra elección la reemplace. Si el almacenamiento no está disponible, solo dura hasta que se descarga la página. No se infiere ninguna elección a partir de redirecciones, URLs o cambios en `<html lang>`.

La selección registra la intención, no la navegación exitosa. La preferencia del navegador, el lenguaje real de la página y la elección explícita permanecen separadas. El recopilador almacena la elección; el cálculo actual basado en navegador de la brecha del panel de control permanece sin cambios.

## Verificar tu dominio

En la **Configuración analítica** de tu proyecto, guarda el dominio de tu sitio. La tarjeta **Verificar propiedad del dominio** muestra el nombre exacto del registro y el valor para tu proyecto. Agrega un registro de texto con tu proveedor de dominio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nombre | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Usa el dominio y el token mostrados en tu configuración. Algunos proveedores añaden el dominio automáticamente; en ese caso escribe solo `_glossia-verify` como el nombre. Tras publicar el registro, haz clic en **Verificar dominio**. Los cambios pueden tardar en estar disponibles, por lo que, si no encuentras el registro inmediatamente, inténtalo de nuevo.

Si no puedes editar los registros de dominio, expande **Alternativa: verifica con una etiqueta meta del inicio del sitio**. Copia la etiqueta generada en el `<head>` de tu página de inicio y publícala:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Cualquiera de estos métodos demuestra el control sobre el dominio configurado. Glossia comprueba el registro o la página del dominio, por lo que copiar el token en otro sitio web no verifica la propiedad. El token es una prueba pública, no una contraseña.

Una vez verificado el dominio, Glossia registra eventos desde tu fragmento de seguimiento. El fragmento por sí solo no verifica la propiedad. Cambiar el dominio configurado requiere verificación nuevamente.

## Verificar que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` a `https://glossia.ai/v1/collect` devuelve `202 Accepted`.
3. Tras la recopilación y el procesamiento, la vista de página aparece bajo **Analítica** en el panel de control de tu proyecto. Las traducciones ejecutadas en la página Resumen están separadas del tráfico del sitio web.

Una respuesta `202 Accepted` confirma que la solicitud llegó al recopilador. Los dominios desconocidos o no verificados también se aceptan pero no registran eventos, por lo que confirma que el dominio configurado está verificado en la configuración analítica del proyecto.

## ¿Qué se recopila?

El navegador envía la URL de la página, remitente, `navigator.languages`), lenguaje real de la página (`<html lang>`)? Traducciones publicitadas (`hreflang` enlaces), lenguaje elegido explícitamente cuando se observa, zona horaria y ancho de pantalla, más un id de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización contra los idiomas objetivo de tu proyecto, traducciones publicitadas y lenguaje real de la página. El id de sesión y la elección explícita usan `sessionStorage`; no se establecen cookies y no se fingerprintea.
