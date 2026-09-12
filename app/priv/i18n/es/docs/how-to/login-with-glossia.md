%{
  title: "Iniciar sesión con Glossia",
  summary:
    "Permita que los usuarios inicien sesión en su aplicación con su cuenta de Glossia usando OAuth 2.1.",
  category: "Guías",
  order: 2
}
---
Esta guía le guiará al agregar "Iniciar sesión con Glossia" a su aplicación. Al finalizar, sus usuarios podrán iniciar sesión con su cuenta de Glossia y su aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia usa **OAuth 2.1 con PKCE** (Llave de prueba para intercambio de código). PKCE es requerido para todos los clientes, incluidas las aplicaciones del lado del servidor.

## 1\. Registre su aplicación OAuth

Tiene dos opciones para registrar su aplicación:

### Opción A: A través del panel de control (recomendado)

1. Inicie sesión en Glossia y vaya al panel de control de su cuenta.
2. Abre la **API** sección desde la barra lateral y haz clic en **Aplicaciones OAuth**.
3. Haz clic en **Nueva aplicación**.
4. Complete la aplicación **nombre** y **URL de devolución de llamada** (también llamado URI de redirección).
5. Haga clic **Crear aplicación**.

Tras la creación, anote el **Client ID** y **Client secret**. El secreto se muestra una vez, así que guárdelo de forma segura.

### Opción B: Registro dinámico del cliente

Envíe una `POST` solicitud a `/oauth/register`:

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

## 2\. Genera un desafío de código PKCE

Antes de redirigir al usuario, genera un verificador de código PKCE y un desafío:

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

## 3\. Redirige al usuario a Glossia

Construye la URL de autorización y redirige el navegador del usuario:

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**Parámetros:**

| Parámetro | Obligatorio | Descripción |
|-----------|----------|-------------|
| `response_type` | Sí | Siempre `code` |
| `client_id` | Sí | El ID de cliente de su aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de devolución de llamada registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre `S256` |
| `scope` | No. | Lista separada por espacios de [alcances](/docs/reference/apis/authentication). Si se omite, predeterminado al acceso mínimo |
| `state` | Recomendado | Una cadena aleatoria para prevenir ataques CSRF. Verifica que coincida cuando el usuario vuelve |

El usuario verá una pantalla de consentimiento mostrando el nombre de tu aplicación y los alcances solicitados. Después de aprobar, Glossia redirige de vuelta a tu URL de devolución con un código de autorización.

## 4\. Canjear el código por tokens

Cuando el usuario es redirigido de vuelta a tu URL de devolución, la URL contendrá un `code` Parámetro:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Primero, verifica que `state` coincide con lo que enviaste en el paso 3. Luego canjea el código por tokens:

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

Guarda ambos tokens de forma segura. El token de acceso se utiliza para las solicitudes de API. El token de renovación se utiliza para obtener un nuevo token de acceso cuando el actual caduca.

## 5\. Llama a la API en nombre del usuario

Utiliza el token de acceso para realizar solicitudes de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

El alcance del token limita los endpoints a los que puedes acceder. La autorización a nivel de recurso sigue aplicándose - por ejemplo, un token con `project:read` solo puede leer los proyectos a los que el usuario tiene acceso.

## 6\. Renovar el token

Cuando el token de acceso caduca, utiliza el token de renovación para obtener uno nuevo sin enviar al usuario a través del flujo de consentimiento de nuevo:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Revocar un token

Cuando un usuario se desconecta de tu aplicación o ya no necesitas acceso, revoca el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Elegir alcances

Solicita solo los alcances que tu aplicación necesita. Aquí hay algunas combinaciones comunes:

| Caso de uso | Alcances |
|----------|--------|
| Leer perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Gestionar proyectos | `user:read project:read project:write` |
| Acceso completo a la organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Ver la [referencia completa de alcances](/docs/reference/apis/authentication) para todos los alcances disponibles.

## Puntos finales de descubrimiento

Tu aplicación puede descubrir automáticamente los puntos finales de OAuth de Glossia obteniendo los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con el `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`y otros detalles. El uso de descubrimiento hace que tu integración sea resiliente a cambios de punto final.

## Gestión de errores

### Errores de autorización

Si el usuario niega el consentimiento o sucede un error durante la autorización, Glossia redirige a tu URL de retorno con un `error` parámetro:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Códigos de error comunes:

| Error | Significado |
|-------|---------|
| `access_denied` | El usuario denegó la solicitud de autorización |
| `invalid_request` | La solicitud carece de un parámetro requerido |
| `invalid_scope` | Uno o más alcances solicitados no son válidos |

### Errores de token

El endpoint del token devuelve HTTP 400 con un cuerpo de error JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Límites de tasa

Los endpoints de OAuth tienen límite de tasa por IP. Si excedes el límite, recibirás HTTP 429. Ver el [referencia de limitación de tasa](/docs/reference/apis/authentication) para más detalles.

## Lista de verificación de seguridad

Antes de pasar a producción, verifique que su implementación siga estas prácticas:

- Utilice siempre HTTPS para las URLs de callback en producción
- Valide el `state` parámetro en el callback para prevenir el CSRF
- Almacene los tokens cifrados en reposo
- Nunca exponga tokens en JavaScript del lado del cliente ni en las URLs del navegador
- Utilice el conjunto mínimo de ámbitos necesarios
- Maneje la expiración de los tokens de forma fluida con tokens de refresco
- Revocar los tokens cuando los usuarios se desconectan o eliminan su cuenta