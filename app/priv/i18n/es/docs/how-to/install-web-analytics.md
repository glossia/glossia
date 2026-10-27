%{
  title: "Instalar analítica web",
  summary:
    "Agregue el SDK web de Glossia a su sitio con una línea de HTML o vía npm, y comience a recopilar señales de localización.",
  category: "Guía",
  section: "analytics",
  order: 1
}
---

Esta guía asume que tienes un proyecto Glossia con su dominio del sitio configurado en las configuraciones de análisis del proyecto. La recopilación se identifica mediante ese dominio, por lo que no hay ninguna clave ni secreto que copiar.

## Opción A: etiqueta de script

Añade este fragmento a cada página, idealmente en `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

La biblioteca se inicializa automáticamente, envía una vista de página al cargar, y registra las vistas de página posteriores durante la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` se inicializa por defecto a `window.location.hostname` cuando se omite, por lo que puedes omitirlo en un sitio de un solo dominio. Para usar un endpoint de recopilación personalizado, añade `data-endpoint="https://collect.your-host.com"`.

Si tu sitio usa una directiva de seguridad de contenido, permite `https://glossia.ai` en `script-src` (o `script-src-elem` cuando está presente) y `connect-src`. El script se carga desde `/assets/glossia-web.js` y envía eventos a `/v1/collect` en el mismo origen.

## Opción B: npm

Instala el paquete:

```bash
npm install @glossia/web
```

Inicia la tarea una vez en el punto de entrada de tu aplicación:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Configura el endpoint de recopilación explícitamente al usar el paquete en tu propio paquete, ya que no hay una dirección de script alojado desde la que inferirlo.

`domain` se infiere de `window.location.hostname` para que la biblioteca registre eventos contra el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribirlo, por ejemplo para enviar eventos desde un origen de pruebas al mismo proyecto que el de producción.

Para registrar un evento personalizado, por ejemplo una inscripción:

```ts
glossia.track("signup");
```

## Registra elecciones explícitas de idioma

Para distinguir la elección del visitante de su preferencia del navegador, llama a la biblioteca en el manejador de acciones del usuario del selector de idioma, antes de navegar:

```js
glossia.selectLanguage("zh-Hans");
```

Este método está disponible en la biblioteca importada después de `glossia.init()`, y en el global `glossia` al usar el script alojado.

Alternativamente, anota los enlaces de cambio de idioma de mismo origen:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Usa una integración por acción, no ambas. Los enlaces anotados registran la activación real del usuario, incluida la activación por teclado. Ignoran los clics scripteados, las descargas, los clics modificados, los destinos de otro origen, y los enlaces que abren otra pestaña o marco, sin impedir la navegación.

La biblioteca envía inmediatamente un `language_selection` evento e incluye el idioma elegido (`cl`) en los eventos subsiguientes. La elección se almacena en `sessionStorage` para la pestaña y el origen actuales hasta que otra elección la reemplace. Si el almacenamiento no está disponible, dura solo hasta que la página se descargue. No se infiere ninguna elección desde redirecciones, URLs o cambios en `<html lang>`.

La selección registra la intención, no la navegación exitosa. La preferencia del navegador, el idioma real de la página y la elección explícita permanecen separadas. El recopilador verifica una elección válida en lugar de las preferencias del navegador al calcular la brecha de localización. Una elección solo elimina la brecha si coincide con un objetivo del proyecto, una traducción anunciada o el idioma real de la página; un idioma elegido no disponible aún tiene una brecha. Las elecciones faltantes o inválidas usan las preferencias del navegador como antes. Los totales y colgantes del panel de control usan la decisión almacenada de cada evento; los indicadores históricos no cambian.

## Verifica tu dominio

En **Configuración de análisis** de tu proyecto, guarda tu dominio del sitio. La tarjeta **Verificar propiedad del dominio** muestra el nombre y valor exactos del registro de tu proyecto. Añade un registro de texto con tu proveedor de dominio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nombre | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Usa el dominio y el token mostrados en tu configuración. Algunos proveedores añaden el dominio automáticamente; en ese caso, introduce solo `_glossia-verify` como el nombre. Después de publicar el registro, haz clic en **Verifica dominio**. Los cambios pueden tardar en estar disponibles, por lo que repite si el registro no se encuentra inmediatamente.

Si no puedes editar los registros de tu dominio, expande **Alternativa: verificar con una etiqueta meta de la página de inicio**. Copia la etiqueta generada en el `<head>` de tu página de inicio y publícala:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Cualquiera de estos métodos demuestra el control del dominio configurado. Glossia verifica el registro de ese dominio o la página de inicio; por lo tanto, copiar el token en otro sitio web no verifica la propiedad. El token es prueba pública, no una contraseña.

Una vez que el dominio está verificado, Glossia registra eventos desde tu fragmento de seguimiento. El fragmento por sí solo no verifica la propiedad. Cambiar el dominio configurado requiere verificación nuevamente.

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma que una solicitud `POST` a `https://glossia.ai/v1/collect` devuelve `202 Accepted`.
3. Después de la recopilación y el procesamiento, la vista de página aparece debajo de **Análisis** en el panel de control de tu proyecto. Las traducciones que se ejecutan en la página general están separadas del tráfico del sitio web.

Una respuesta `202 Accepted` confirma que la solicitud llegó al recopilador. Los dominios ilegales o no verificados también se aceptan pero no registran eventos, por lo que confirma que el dominio configurado está verificado en las configuraciones de análisis del proyecto.

## ¿Qué se recopila

El navegador envía la URL de la página, el reenviador, `navigator.languages`, el idioma real de la página (`<html lang>`), las traducciones anunciadas (`hreflang` enlaces), el idioma elegido explícitamente cuando se observa, la zona horaria y el ancho de pantalla, más un ID de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización contra los idiomas objetivo del proyecto, las traducciones anunciadas y el idioma real de la página. El ID de sesión y la elección explícita usan `sessionStorage`; no se establecen cookies y nada se fingerprintea.
