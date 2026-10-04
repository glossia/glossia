%{
  title: "Instalar análisis web",
  summary:
    "Agregue el SDK web de Glossia a su sitio con una línea de HTML o vía npm, y comience a recopilar señales de localización.",
  category: "Guía",
  section: "analytics",
  order: 1
}
---
Esta guía asume que tienes un proyecto de Glossia con el dominio de su sitio configurado en los ajustes de análisis del proyecto. La colección se identifica mediante ese dominio, por lo que no hay clave ni secreto que copiar.

## Opción A: etiqueta script

Añade este fragmento a todas las páginas, idealmente en la `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

El SDK se inicializa automáticamente, envía una vista de página al cargar y registra las vistas de página posteriores durante la navegación del lado del cliente en aplicaciones de una sola página. `data-domain` por defecto `window.location.hostname` cuando se omite, por lo que puedes insertarlo en un sitio de dominio único. Para utilizar un endpoint de colección personalizado, añade `data-endpoint="https://collect.your-host.com"`.

Si tu sitio utiliza una política de seguridad del contenido, permite `https://glossia.ai` en ambos `script-src` (o `script-src-elem` cuando estén presentes) y `connect-src`. El script se carga desde `/assets/glossia-web.js` y envía eventos a `/v1/collect` en el mismo origen.

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

Configura el endpoint de colección explícitamente cuando utilices el paquete en tu propio paquete, ya que no hay ninguna dirección de script alojada de la que inferirlo.

`domain` se infiere de `window.location.hostname` para que el SDK registre los datos en el proyecto registrado para tu sitio. Pasa `{ domain: "example.com" }` para sobrescribirlo, por ejemplo para enviar eventos desde un origen staging al mismo proyecto que producción.

Para registrar un evento personalizado, por ejemplo un registro:

```ts
glossia.track("signup");
```

## Verifica tu dominio

En su proyecto **Configuración de análisis**, guarde el dominio de su sitio. El **Verificación de la propiedad del dominio** La tarjeta muestra el nombre exacto del registro y el valor para su proyecto. Agregue un registro de texto con su proveedor de dominio:

| Campo | Valor |
| --- | --- |
| Tipo | `TXT` ([registro de texto](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nombre | `_glossia-verify.example.com` |
| Valor | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilice el dominio y el token mostrados en su configuración. Algunos proveedores agregan el dominio automáticamente; en ese caso ingrese solo `_glossia-verify` como el nombre. Después de publicar el registro, haga clic **Verificar dominio**. Los cambios pueden tardar en estar disponibles, así que reintente si no encuentra el registro inmediatamente.

Si no puede editar sus registros de dominio, expanda **Alternativa: verifique con una etiqueta meta de la página de inicio**. Copie la etiqueta generada en la `<head>` de su página de inicio y publícala:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Cualquiera de los métodos demuestra control sobre el dominio configurado. Glossia verifica el registro o la página de inicio de ese dominio, por lo que copiar el token en otro sitio web no verifica la propiedad. El token es una prueba pública, no una contraseña.

Una vez que el dominio esté verificado, Glossia registra eventos desde tu fragmento de seguimiento. El fragmento por sí solo no verifica la propiedad. Cambiar el dominio configurado requiere volver a verificar.

## Verifica que funciona

1. Abre tu sitio en un navegador.
2. Abre la pestaña de red y confirma una `POST` petición a `https://glossia.ai/v1/collect` devuelve `202 Accepted`.
3. Tras la recopilación y el procesamiento, la vista de página aparece bajo **Análisis** en el panel de su proyecto. Las ejecuciones de traducción en la página de Visión general se separan del tráfico del sitio web.

Una `202 Accepted` respuesta que confirma que la solicitud llegó al recolector. También se aceptan dominios desconocidos o no verificados, pero no registran eventos, por lo que confirme que el dominio configurado está verificado en los ajustes de análisis del proyecto.

## Qué se recopila

El navegador envía la URL de la página, el remitente, `navigator.languages`, la zona horaria y el ancho de pantalla, más un id de sesión por pestaña. El servidor añade el país (desde GeoIP) y calcula la brecha de localización frente a los idiomas objetivo de su proyecto. No se establecen cookies y no se identifican las huellas digitales.