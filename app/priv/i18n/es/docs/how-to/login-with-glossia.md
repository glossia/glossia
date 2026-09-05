%{
  title: "Iniciar sesión con Glossia",
  summary:
    "Permitir a los usuarios iniciar sesión en su aplicación con su cuenta de Glossia usando OAuth 2.1.",
  category: "how-to",
  order: 2
}
---
Esta guía le muestra cómo agregar "Iniciar sesión con Glossia" a su aplicación. Al finalizar, sus usuarios podrán iniciar sesión con su cuenta de Glossia y su aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia utiliza **OAuth 2.1 con PKCE** (Clave de Prueba para el Intercambio de Códigos). PKCE es obligatorio para todos los clientes, incluidas las aplicaciones de lado del servidor.

## 1\. Registre su aplicación OAuth

Tiene dos opciones para registrar su aplicación:

### Opción A: A través del panel de control (recomendado)

1. Inicie sesión en Glossia y vaya a su panel de control de cuenta.
2. Abre la **API** sección en la barra lateral y haz clic **Aplicaciones OAuth**.
3. Haz clic **Nueva aplicación**.
4. Rellene la aplicación **nombre** y **URL de retorno** (también llamada URI de redirección).
5. Haga clic **Crear aplicación**.

Después de crear, anota la **ID del cliente** y **secreto del cliente**. El secreto se muestra una sola vez, así que guárdalo de forma segura.

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

## 3\. Redirija al usuario a Glossia

Construya la URL de autorización y redirija el navegador del usuario:

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
| `client_id` | Sí | ID del cliente de su aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de devolución registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre | `S256` |
| `scope` | No | Lista separada por espacios de [alcances](/docs/reference/apis/authentication). Por defecto permite el acceso mínimo si se omite |
| `state` | Recomendado | Una cadena aleatoria para prevenir ataques CSRF. Verifica que coincide cuando el usuario regresa |

El usuario verá una pantalla de consentimiento que muestra el nombre de tu aplicación y los alcances solicitados. Después de que aprueben, Glossia redirige de vuelta a tu URL de devolución de llamada con un código de autorización.

## 4\. Intercambia el código por tokens

Cuando el usuario es redirigido de vuelta a tu URL de devolución de llamada, la URL contendrá un `code` parámetro:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Primero, verifica que `state` coincida con lo que enviaste en el paso 3. Luego canjea el código por tokens:

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

Almacena ambos tokens de forma segura. El token de acceso se usa para las solicitudes de API. El token de refresco se usa para obtener un nuevo token de acceso cuando el actual expira.

## 5\. Llama a la API en nombre del usuario

Utiliza el token de acceso para realizar solicitudes de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

El alcance del token limita los endpoints a los que puedes acceder. La autorización a nivel de recurso aún se aplica - por ejemplo, un token con `project:read` solo puede leer los proyectos a los que el usuario tiene acceso.

## 6\. Refresca el token

Cuando el token de acceso expira, utiliza el token de refresco para obtener uno nuevo sin enviar al usuario nuevamente por el flujo de consentimiento:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Revocar un token

Cuando un usuario desconecta tu aplicación o ya no necesitas acceso, revoca el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Elegir ámbitos

Solicita únicamente los ámbitos que tu aplicación necesita. Aquí tienes algunas combinaciones comunes:

| Caso de uso | Ámbitos |
|----------|--------|
| Leer perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Gestionar proyectos | `user:read project:read project:write` |
| Acceso completo a la organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Ver la [referencia completa de alcances](/docs/reference/apis/authentication) para todos los ámbitos disponibles.

## Puntos finales de descubrimiento

Tu aplicación puede descubrir automáticamente los puntos finales OAuth de Glossia recuperando los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`y otros detalles. El uso del descubrimiento hace que tu integración sea resistente a cambios en los puntos finales.

## Manejo de errores

### Errores de autorización

Si el usuario niega el consentimiento o ocurre un error durante la autorización, Glossia redirige a tu URL de devolución con un `error` parámetro:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Códigos de error comunes:

| Error | Significado |
|-------|---------|
| `access_denied` | El usuario denegó la solicitud de autorización |
| `invalid_request` | La solicitud le falta un parámetro requerido |
| `invalid_scope` | Uno o más alcances solicitados no son válidos |

### Errores de token

El punto final del token devuelve HTTP 400 con un cuerpo de error JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Límites de tasa

Los puntos finales OAuth tienen límites de tasa por IP. Si excede el límite, recibirá HTTP 429. Consulte el [referencia de limitación de tasa](/docs/reference/apis/authentication) para más detalles.

## Lista de verificación de seguridad

Antes de pasar a producción, verifique que su implementación siga estas prácticas:

- Utilice siempre HTTPS para las URLs de callback en producción
- Valide el `state` parámetro en el callback para prevenir CSRF
- Almacene los tokens cifrados en reposo
- Nunca expongas tokens en JavaScript del lado del cliente ni en las URLs del navegador
- Usa el conjunto mínimo de ámbitos necesarios
- Gestiona la expiración de los tokens de forma adecuada con tokens de refresco
- Revoca los tokens cuando los usuarios se desconectan o eliminan su cuenta
