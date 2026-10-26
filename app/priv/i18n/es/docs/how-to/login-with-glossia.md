%{
  title: "Iniciar sesión con Glossia",
  summary:
    "Permita que los usuarios inicien sesión en su aplicación con su cuenta de Glossia mediante OAuth 2.1.",
  category: "Guía",
  section: "platform",
  order: 2
}
---

Esta guía le muestra cómo agregar "Iniciar sesión con Glossia" a su aplicación. Al final, sus usuarios poderão iniciar sesión con su cuenta de Glossia y su aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia utiliza **OAuth 2.1 con PKCE** (Prueba de clave para el intercambio de código). PKCE es obligatorio para todos los clientes, incluidas las aplicaciones de lado del servidor.

## 1. Registrar su aplicación OAuth

Tiene dos opciones para registrar su aplicación:

### Opción A: A través del panel de control (recomendado)

1. Inicie sesión en Glossia y vaya al panel de control de su cuenta.
2. Abra la sección **API** desde la barra lateral y haga clic en **Aplicaciones OAuth**.
3. Haga clic en **Nueva aplicación**.
4. Complete el **nombre** de la aplicación y el **URL de retorno** (también denominado URI de redirección).
5. Haga clic en **Crear aplicación**.

Después de la creación, anote el **ID de cliente** y el **Secret del cliente**. El secreto se muestra una vez, por lo que guárdelo de forma segura.

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

## 2. Generar un desafío de código PKCE

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

## 3. Redirigir al usuario a Glossia

Construya la URL de autorización y redirija el navegador del usuario:

```
https://glossia.ai/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=https://myapp.com/auth/callback
  &code_challenge=YOUR_CODE_CHALLENGE
  &code_challenge_method=S256
  &scope=user:read+project:read
  &state=RANDOM_STATE_VALUE
```

**Parámetros:**

| Parámetro | Obligatorio | Descripción |
|-----------|----------|-------------|
| `response_type` | Sí | Siempre `code` |
| `client_id` | Sí | El ID de cliente de su aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de retorno registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre `S256` |
| `scope` | No | Lista separada por espacios de [alcances](/docs/reference/apis/authorization) que no son de acción no se otorgan si se omiten. |
| `state` | Recomendado | Una cadena aleatoria para prevenir ataques CSRF. Verifique que coincide cuando el usuario vuelve. |

El usuario verá una pantalla de consentimiento que muestra el nombre de su aplicación y los alcances solicitados. Después de aprobar, Glossia redirige de vuelta a su URL de retorno junto con un código de autorización.

## 4. Intercambiar el código por tokens

Cuando el usuario se redirija de nuevo a su URL de retorno, la URL contendrá un parámetro `code`:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Primero, verifique que el valor `state` coincida con lo que envió en el paso 3. Luego, intercambie el código por tokens:

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

Guarde ambos tokens de forma segura. El token de acceso se utiliza para las solicitudes de API. El token de renovación se utiliza para obtener un nuevo token de acceso cuando el actual expira.

## 5. Llamar a la API en nombre del usuario

Utilice el token de acceso para realizar solicitudes de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Los alcances del token limitan qué endpoints puede acceder. La autorización a nivel de recurso sigue aplicando -- por ejemplo, un token con `project:read` solo puede leer los proyectos a los que el usuario tiene acceso.

## 6. Renovar el token

Cuando el token de acceso expira, utilice el token de renovación para obtener uno nuevo sin enviar al usuario nuevamente a través del flujo de consentimiento:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revocar un token

Cuando un usuario desconecte su aplicación o ya no necesite acceso, revogue el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Elegir alcances

Solicite solo los alcances que su aplicación necesita. Aquí hay algunas combinaciones comunes:

| Caso de uso | Alcances |
|----------|--------|
| Leer perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Administrar proyectos | `user:read project:read project:write` |
| Administrar recursos de organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consulte la [referencia de alcances](/docs/reference/apis/authorization) para ver todos los alcances disponibles.

## Endpoints de descubrimiento

Su aplicación puede descubrir automáticamente los endpoints de OAuth de Glossia al obtener los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con los `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` y otros detalles. El uso del descubrimiento hace que su integración sea resistente a los cambios de endpoint.

## Manejo de errores

### Errores de autorización

Si el usuario deniega el consentimiento o algo sale mal durante la autorización, Glossia redirige a su URL de retorno con un parámetro `error`:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Códigos de error comunes:

| Error | Significado |
|-------|---------|
| `access_denied` | El usuario denegó la solicitud de autorización |
| `invalid_request` | La solicitud carece de un parámetro obligatorio |
| `invalid_scope` | Uno o más alcances solicitados no son válidos |

### Errores de token

El endpoint devuelve HTTP 400 con un cuerpo de error JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Límites de tasa

Los endpoints de OAuth tienen límites de tasa por IP. Si llega al límite, recibirá HTTP 429. Consulte la [referencia de limitación de tasa](/docs/reference/apis/authentication) para más detalles.

## Lista de verificación de seguridad

Antes de pasar a producción, verifique que su implementación cumpla con estas prácticas:

- Siempre use HTTPS para las URL de retorno en producción
- Valide el parámetro `state` en el callback para prevenir CSRF
- Guarde los tokens cifrados en reposo
- Nunca exponga los tokens en JavaScript del lado del cliente o en las URLs del navegador
- Utilice el conjunto mínimo de alcances necesarios
- Maneje la expiración del token adecuadamente con tokens de renovación
- Revogue los tokens cuando los usuarios se desconecten o eliminen su cuenta
