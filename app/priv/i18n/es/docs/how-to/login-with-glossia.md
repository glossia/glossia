%{
  title: "Iniciar sesión con Glossia",
  summary:
    "Permite a los usuarios iniciar sesión en su aplicación con su cuenta de Glossia usando OAuth 2.1.",
  category: "Tutorial",
  section: "platform",
  order: 2
}
---

Esta guía te muestra cómo añadir "Iniciar sesión con Glossia" a tu aplicación. Al final, tus usuarios podrán iniciar sesión con su cuenta de Glossia y tu aplicación tendrá un token de acceso para llamar a la API de Glossia en su nombre.

Glossia usa **OAuth 2.1 con PKCE** (Prueba clave para el intercambio de códigos). PKCE es obligatorio para todos los clientes, incluidas las aplicaciones del lado del servidor.

## 1. Registra tu aplicación OAuth

Tienes dos opciones para registrar tu aplicación:

### Opción A: A través del panel de control (recomendado)

1. Inicia sesión en Glossia y ve a tu panel de control de la cuenta.
2. Abre la sección **API** de la barra lateral y haz clic en **Aplicaciones OAuth**.
3. Haz clic en **Nueva aplicación**.
4. Rellena el **nombre** de la aplicación y la **URL de devolución** (también llamada URI de redirección).
5. Haz clic en **Crear aplicación**.

Después de la creación, anota el **ID de cliente** y el **secreto de cliente**. El secreto solo se muestra una vez, así que guárdalo de forma segura.

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

## 2. Genera un desafío de código PKCE

Antes de redirigir al usuario, genera un comprobador de código PKCE y un desafío:

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

## 3. Redirige al usuario a Glossia

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

| Parámetro | Obligatorio | Descripción |
|-----------|----------|-------------|
| `response_type` | Sí | Siempre `code` |
| `client_id` | Sí | El ID de cliente de tu aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de devolución registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre `S256` |
| `scope` | No | Lista separada por espacios de [alcances](/docs/reference/apis/authorization). No se conceden acciones si se omite |
| `state` | Recomendado | Una cadena aleatoria para prevenir ataques CSRF. Verifica que coincida cuando el usuario regrese |

El usuario verá una pantalla de consentimiento mostrando el nombre de tu aplicación y los alcances solicitados. Después de su aprobación, Glossia redirigirá de nuevo a tu URL de devolución con un código de autorización.

## 4. Intercambia el código por tokens

Cuando el usuario sea redirigido de nuevo a tu URL de devolución, la URL contendrá un parámetro `code`:

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

Guarda ambos tokens de forma segura. El token de acceso se utiliza para las solicitudes de API. El token de renovación se usa para obtener un nuevo token de acceso cuando el actual caduca.

## 5. Llama a la API en nombre del usuario

Usa el token de acceso para realizar solicitudes de API autenticadas:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Los alcances del token limitan los puntos finales a los que puedes acceder. La autorización a nivel de recurso aún se aplica - por ejemplo, un token con `project:read` solo puede leer los proyectos a los que el usuario tiene acceso.

## 6. Renueva el token

Cuando el token de acceso caduque, usa el token de renovación para obtener uno nuevo sin enviar al usuario nuevamente por el flujo de consentimiento:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revoca un token

Cuando un usuario desconecte tu aplicación o ya no se necesite acceso, revoca el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Selección de alcances

Solicita solo los alcances que necesita tu aplicación. Aquí hay algunas combinaciones comunes:

| Caso de uso | Alcances |
|----------|--------|
| Ver perfil de usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Administrar proyectos | `user:read project:read project:write` |
| Administrar recursos de organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consulta la [referencia de alcances](/docs/reference/apis/authorization) para todos los alcances disponibles.

## Puntos finales de descubrimiento

Tu aplicación puede descubrir automáticamente los puntos finales de OAuth de Glossia obteniendo el metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con los `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` y otros detalles. El uso de descubrimiento hace que tu integración sea resiliente a los cambios en los puntos finales.

## Manejo de errores

### Errores de autorización

Si el usuario niega el consentimiento o algo falla durante la autorización, Glossia redirige a tu URL de devolución con un parámetro `error`:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Códigos de error comunes:

| Código | Significado |
|-------|---------|
| `access_denied` | El usuario denegó la solicitud de autorización |
| `invalid_request` | La solicitud falta un parámetro obligatorio |
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

Los puntos finales de OAuth tienen límites de tasa por IP. Si alcanzas el límite, recibirás HTTP 429. Consulta la [referencia de límites de tasa](/docs/reference/apis/authentication) para más detalles.

## Lista de verificación de seguridad

Antes de ir a producción, verifica que tu implementación siga estas prácticas:

- Usa siempre HTTPS para las URL de devolución en producción
- Valida el parámetro `state` en la devolución para prevenir CSRF
- Almacena los tokens encriptados en reposo
- Nunca expongas tokens en JavaScript de lado del cliente o URL de navegador
- Usa el conjunto mínimo de alcances necesarios
- Gestiona la caducidad del token de manera adecuada con tokens de renovación
- Revoca los tokens cuando los usuarios se desconecten o eliminen su cuenta
