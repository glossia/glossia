%{
  title: "Iniciar sesión con Glossia",
  summary:
    "Permita a los usuarios iniciar sesión en su aplicación con su cuenta de Glossia utilizando OAuth 2.1.",
  category: "Guía",
  order: 2
}
---
Esta guía te guiará a través de añadir "Iniciar sesión con Glossia" a tu aplicación. Al finalizar, tus usuarios podrán iniciar sesión con su cuenta de Glossia y tu aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia utiliza **OAuth 2.1 con PKCE** (Clave de prueba para el intercambio de código). PKCE es obligatorio para todos los clientes, incluidas las aplicaciones del lado del servidor.

## 1\. Registra tu aplicación OAuth

Tienes dos opciones para registrar tu aplicación:

### Opción A: A través del panel de control (recomendado)

1. Inicia sesión en Glossia y ve a tu panel de control de la cuenta.
2. Abre la **API** sección de la barra lateral y haz clic **Aplicaciones OAuth**.
3. Haz clic **Nueva aplicación**.
4. Rellene la aplicación **nombre** y **URL de retorno** (también llamada URI de redirección).
5. Haga clic **Crear aplicación**.

Después de la creación, anota el **ID del cliente** y **Secret del cliente**. El secreto se muestra una vez, por lo tanto, guárdalo de forma segura.

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
| `client_id` | Sí | el ID de cliente de tu aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de devolución de llamada registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre `S256` |
| `scope` | No. | Lista separada por espacios de [alcances](/docs/reference/apis/authentication). Por defecto, el acceso mínimo si se omite |
| `state` | Recomendado | Una cadena aleatoria para prevenir ataques CSRF. Verifique que coincide cuando el usuario regresa

El usuario verá una pantalla de consentimiento que muestra el nombre de su aplicación y los alcances solicitados. Después de su aprobación, Glossia redirige de vuelta a su URL de devolución con un código de autorización.

## 4\. Intercambiar el código por tokens

Cuando el usuario es redirigido de vuelta a su URL de devolución, la URL contendrá un `code` parámetro:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

Primero, verifique que `state` coincida con lo que envió en el paso 3. Luego canjée el código por tokens:

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

Guarda ambos tokens de forma segura. El token de acceso se utiliza para solicitudes de API. El token de refresco se utiliza para obtener un nuevo token de acceso cuando el actual expira.

## 5\. Llama a la API en nombre del usuario

Usa el token de acceso para realizar solicitudes API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Los alcances del token limitan qué endpoints puedes acceder. La autorización a nivel de recurso sigue aplicando -- por ejemplo, un token que `project:read` puede solo leer los proyectos a los que el usuario tiene acceso.

## 6\. Refresca el token

Cuando el token de acceso caduca, usa el token de refresco para obtener uno nuevo sin enviar al usuario por el flujo de consentimiento nuevamente:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. Revocar un token

Cuando un usuario desconecte su aplicación o ya no necesite acceso, revoque el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Elegir alcances

Solicite únicamente los alcances que necesita su aplicación. Aquí hay algunas combinaciones comunes:

| Caso de uso | Alcances |
|----------|--------|
| Leer perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Gestionar proyectos | `user:read project:read project:write` |
| Acceso completo a la organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Ver la [referencia de ámbitos completos](/docs/reference/apis/authentication) para todos los ámbitos disponibles.

## Endpoints de descubrimiento

Tu aplicación puede descubrir automáticamente los endpoints OAuth de Glossia obteniendo los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con el `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`y otros detalles. El uso del descubrimiento hace que su integración sea resistente a cambios en los puntos finales.

## Manejo de errores

### Errores de autorización

Si el usuario deniega el consentimiento o algo falla durante la autorización, Glossia redirige a tu URL de callback con un `error` parámetro:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

Códigos de error comunes:

| Error | Significado |
|-------|---------|
| `access_denied` | El usuario denegó la solicitud de autorización |
| `invalid_request` | Falta un parámetro requerido en la solicitud |
| `invalid_scope` | Uno o más alcances solicitados no son válidos |

### Errores de token

El endpoint de token devuelve HTTP 400 con un cuerpo de error JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Límites de tasa

Los endpoints de OAuth tienen límites de tasa por IP. Si se excede el límite, recibirá HTTP 429. Consulte el [Referencia de limitación de tasas](/docs/reference/apis/authentication) para más detalles.

## Lista de verificación de seguridad

Antes de pasar a producción, verifica que tu implementación siga estas prácticas:

- Usa siempre HTTPS para las URL de callback en producción
- Valida el `state` parámetro en el callback para prevenir CSRF
- Almacena los tokens cifrados en reposo
- Nunca exponga tokens en JavaScript del lado del cliente ni en las URLs del navegador
- Utilice el conjunto mínimo de ámbitos necesarios
- Maneje la expiración de tokens de manera adecuada con tokens de refresco
- Revogue los tokens cuando los usuarios se desconecten o eliminen sus cuentas