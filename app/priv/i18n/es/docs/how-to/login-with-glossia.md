%{
  title: "Iniciar sesión con Glossia",
  summary:
    "Permite a los usuarios iniciar sesión en tu aplicación con su cuenta de Glossia usando OAuth 2.1.",
  category: "Tutoriales",
  order: 2
}
---
Esta guía te muestra cómo agregar "Iniciar sesión con Glossia" a tu aplicación. Al finalizar, tus usuarios podrán iniciar sesión con su cuenta de Glossia y tu aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia usa **OAuth 2.1 con PKCE** (Clave de prueba para intercambio de códigos). PKCE es necesario para todos los clientes, incluidas las aplicaciones del lado del servidor.

## 1\. Registra tu aplicación OAuth

Tienes dos opciones para registrar tu aplicación:

### Opción A: A través del panel de control (recomendado)

1. Inicia sesión en Glossia y ve al panel de control de tu cuenta.
2. Abre la **API** sección de la barra lateral y haz clic en **Aplicaciones OAuth**.
3. Haz clic en **Nueva aplicación**.
4. Rellene la aplicación **nombre** y **URL de devolución** (también llamada URI de redirección).
5. Haga clic **Crear aplicación**.

Tras su creación, anota el **ID del cliente** y **Secreto del cliente**. El secreto se muestra una sola vez, por lo que guárdalo de forma segura.

### Opción B: Registro dinámico del cliente

Envía una `POST` solicitud a `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

La respuesta incluye `client_id` y `client_secret`.

## 2\. Generar un desafío de código PKCE

Antes de redirigir al usuario, genere un verificador de código PKCE y un desafío:

```javascript
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = await generateCodeChallenge(codeVerifier);
// Store codeVerifier in your session -- you will need it in step 4
```

## 3\. Redirigir al usuario a Glossia

Construir la URL de autorización y redirigir el navegador del usuario:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**Parámetros:**

| Parámetro | Requerido | Descripción |
|-----------|----------|-------------|
| `response_type` | Sí | Siempre `code` |
| `client_id` | Sí | El ID del cliente de su aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de callback registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre | `S256` |
| `scope` | Nombre | Lista separada por espacios de [ámbitos](/docs/reference/apis/authentication). Por defecto, acceso mínimo si se omite |
| `state` | Recomendado | Una cadena aleatoria para evitar ataques CSRF. Verifica que coincida cuando el usuario regresa |

El usuario verá una pantalla de consentimiento que muestra el nombre de tu aplicación y los ámbitos solicitados. Tras aprobar, Glossia redirige de nuevo a tu URL de devolución con un código de autorización.

## 4\. Intercambia el código por tokens

Cuando el usuario es redirigido de nuevo a tu URL de devolución, la URL contendrá un `code` parámetro:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Primero, verifica que `state` coincide con lo que enviaste en el paso 3. Luego intercambia el código por tokens:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://myapp.com/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code_verifier=YOUR_CODE_VERIFIER"
```

La respuesta:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

Guarda ambos tokens de forma segura. El token de acceso se utiliza para solicitudes API. El token de renovación se usa para obtener uno nuevo cuando el actual caduca.

## 5\. Llama a la API en nombre del usuario

Utiliza el token de acceso para realizar solicitudes API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Los alcances del token limitan los endpoints a los que puedes acceder. La autorización a nivel de recurso sigue aplicando - por ejemplo, un token con `project:read` solo puede leer los proyectos a los que el usuario tiene acceso.

## 6\. Renueva el token

Cuando el token de acceso caduca, utiliza el token de renovación para obtener uno nuevo sin enviar al usuario a través del flujo de consentimiento nuevamente:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Revocar un token

Cuando un usuario desconecta su aplicación o ya no necesita el acceso, revocar el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Elegir scopes

Solicite solo los scopes que necesita su aplicación. Aquí están algunas combinaciones comunes:

| Caso de uso | Scopes |
|----------|--------|
| Leer perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Gestionar proyectos | `user:read project:read project:write` |
| Acceso completo a la organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Ver la [referencia completa de alcances](/docs/reference/apis/authentication) para todos los alcances disponibles.

## Puntos finales de descubrimiento

Tu aplicación puede descubrir automáticamente los puntos finales OAuth de Glossia al obtener los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con el `authorization_endpoint`\<span class="GlossiaWarning"\>The reassembled document previously failed validation: Markdown text-literal recovery must return a JSON string array of matching length\</span\> Return a corrected translation of only this supplied segment. Preserve every required token present in this segment. `token_endpoint`El documento reensamblado anteriormente falló la validación: la recuperación de texto literal de Markdown devolvió JSON inválido. `revocation_endpoint`y otros detalles. El uso del descubrimiento hace que tu integración sea resiliente ante cambios en el endpoint.

## Manejo de errores

### Errores de autorización

Si el usuario niega el consentimiento o surge un error durante la autorización, Glossia redirige a su URL de callback con un `error` parámetro:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Códigos de error comunes:

| Error | Significado |
|-------|---------|
| `access_denied` | El usuario denegó la solicitud de autorización |
| `invalid_request` | Falta un parámetro requerido en la solicitud |
| `invalid_scope` | Uno o más alcances solicitados no son válidos |

### Errores de token

El punto final de token devuelve HTTP 400 con un cuerpo de error JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Límites de tasa

Los puntos finales de OAuth tienen límites de tasa por IP. Si alcanza el límite, recibirá HTTP 429. Vea el [referencia de limitación de tasas](/docs/reference/apis/authentication) para más detalles.

## Lista de verificación de seguridad

Antes de ir a producción, verifique que su implementación siga estas prácticas:

- Use siempre HTTPS para las URLs de callback en producción
- Valide el `state` parámetro en el callback para prevenir el CSRF
- Almacene los tokens cifrados en reposo
- Nunca exponga tokens en JavaScript de lado del cliente o en las URL del navegador
- Utilice el conjunto mínimo de alcances necesarios
- Gestione la expiración de tokens de forma elegante con tokens de refresco
- Revocar los tokens cuando los usuarios se desconecten o eliminen su cuenta