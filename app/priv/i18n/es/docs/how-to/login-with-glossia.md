%{
  title: "Inicia sesión con Glossia",
  summary:
    "Permita que los usuarios inicien sesión en su aplicación con su cuenta de Glossia mediante OAuth 2.1.",
  category: "Tutorial",
  section: "platform",
  order: 2
}
---

Esta guía te acompaña al agregar "Iniciar sesión con Glossia" a tu aplicación. Al final, tus usuarios podrán iniciar sesión con su cuenta de Glossia y tu aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia utiliza **OAuth 2.1 con PKCE** (clave de prueba para el intercambio de códigos). PKCE es necesario para todos los clientes, incluidas las aplicaciones de lado del servidor.

## ### 1. Registra tu aplicación OAuth

Tienes dos opciones para registrar tu aplicación:

### ### Opción A: A través del panel de control (recomendado)

1. 1\. Inicia sesión en Glossia y ve a tu panel de control de cuenta.
2. 2\. Abre la sección **API** desde la barra lateral y haz clic en **Aplicaciones OAuth**.
3. 3\. Haz clic en **Nueva aplicación**.
4. 4\. Rellena el **nombre** y la **URL de redirección** de la aplicación (también llamada URI de redirección).
5. 5\. Haz clic en **Crear aplicación**.

Después de la creación, anota el **ID del cliente** y el **secreto del cliente**. El secreto se muestra una sola vez, guárdalo de forma segura.

### ## Opción B: Registro dinámico del cliente

Envía `POST` a `/oauth/register`:

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

## ## 2. Genera un desafío de código PKCE

Antes de redirigir al usuario, genera un verificador y desafío de código PKCE:

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

## ## 3. Redirige al usuario a Glossia

Construye la URL de autorización y redirige el navegador del usuario:

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

| Parámetro | Requerido | Descripción |
|-----------|----------|-------------|
| `response_type` | Sí | Siempre `code` |
| `client_id` | Sí | El ID de cliente de tu aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de callback registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre `S256` |
| `scope` | No | Lista separada por espacios de [alcances](/docs/reference/apis/authorization). No se conceden alcances de acción si se omiten |
| `state` | Recomendado | Una cadena aleatoria para prevenir ataques CSRF. Verifica que coincida cuando el usuario regresa |

El usuario verá una pantalla de consentimiento que muestra el nombre de tu aplicación y los alcances solicitados. Después de aprobar, Glossia redirige de vuelta a tu URL de callback con un código de autorización.

## ## 4. Intercambia el código por tokens

Cuando el usuario se redirige de vuelta a tu URL de callback, la URL contendrá el parámetro `code`:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Primero, verifica que `state` coincida con lo que enviaste en el paso 3. Luego intercambia el código por tokens:

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

Guarda ambos tokens de forma segura. El token de acceso se usa para solicitudes de API. El token de refresco se usa para obtener un nuevo token de acceso cuando el actual caduca.

## 5. Llama a la API en nombre del usuario

Usa el token de acceso para hacer solicitudes de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Los alcances del token limitan qué puntos finales puedes acceder. La autorización a nivel de recurso sigue aplicando - por ejemplo, un token con `project:read` solo puede leer proyectos a los que el usuario tiene acceso.

## 6. Refresca el token

Cuando el token de acceso caduca, usa el token de refresco para obtener uno nuevo sin enviar al usuario a través del flujo de consentimiento nuevamente:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revoca un token

Cuando un usuario desconecta tu aplicación o ya no necesitas acceso, revoca el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Elegir alcances

Solicita solo los alcances que necesita tu aplicación. Aquí hay algunas combinaciones comunes:

| Uso de caso | Alcances |
|----------|--------|
| Leer perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Gestionar proyectos | `user:read project:read project:write` |
| Gestionar recursos de la organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consulta la [referencia de alcances](/docs/reference/apis/authorization) para todos los alcances disponibles.

## Puntos de descubrimiento

Tu aplicación puede descubrir los puntos finales OAuth de Glossia automáticamente obteniendo los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con el `authorization_endpoint`, el `token_endpoint`, el `revocation_endpoint` y otros detalles. Usar el descubrimiento hace que tu integración sea resiliente a cambios en los puntos finales.

## Manejo de errores

### Errores de autorización

Si el usuario deniega el consentimiento o algo sale mal durante la autorización, Glossia redirige a tu URL de callback con el parámetro `error`:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Códigos de error comunes:

| Error | Significado |
|-------|---------|
| `access_denied` | El usuario negó la solicitud de autorización |
| `invalid_request` | La solicitud falta un parámetro requerido |
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

Los puntos finales OAuth están limitados por tasa por IP. Si alcanzas el límite, recibirás HTTP 429. Consulta la [referencia de limitación de tasa](/docs/reference/apis/authentication) para más detalles.

## Lista de comprobación de seguridad

Antes de pasar a producción, verifica que tu implementación siga estas prácticas:

- Usa siempre HTTPS para las URLs de callback en producción
- Valida el parámetro `state` en el callback para prevenir CSRF
- Guarda los tokens encriptados en reposo
- Nunca expongas tokens en JavaScript del lado del cliente o en URLs del navegador
- Usa el conjunto mínimo de alcances necesarios
- Gestiona la caducidad de los tokens con fluidez mediante tokens de refresco
- Revoca los tokens cuando los usuarios se desconectan o eliminan su cuenta
