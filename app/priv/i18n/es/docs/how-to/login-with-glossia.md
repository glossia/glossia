%{
  title: "Iniciar sesión con Glossia",
  summary: "Permita que los usuarios inicien sesión en su aplicación con su cuenta de Glossia mediante OAuth 2.1.",
  category: "how-to",
  order: 2
}
---
Esta guía explica cómo añadir «Iniciar sesión con Glossia» a su aplicación. Al finalizar, los usuarios podrán iniciar sesión con su cuenta de Glossia y su aplicación dispondrá de un token de acceso para llamar a la API de Glossia en su nombre.

Glossia utiliza **OAuth 2.1 con PKCE** (clave de prueba para intercambio de código). PKCE es obligatorio para todos los clientes, incluidas las aplicaciones del lado del servidor.

## 1. Registre su aplicación OAuth

Tiene dos opciones para registrar su aplicación:

### Opción A: Desde el panel de control (recomendado)

1. Inicie sesión en Glossia y vaya al panel de control de su cuenta.
2. Abra la sección **API** en la barra lateral y haga clic en **Aplicaciones OAuth**.
3. Haga clic en **Nueva aplicación**.
4. Introduzca el **nombre** de la aplicación y la **URL de devolución de llamada** (también denominada URI de redirección).
5. Haga clic en **Crear aplicación**.

Después de crearla, anote el **ID de cliente** y el **secreto de cliente**. El secreto solo se muestra una vez, así que guárdelo de forma segura.

### Opción B: Registro dinámico de clientes

Envíe una solicitud `POST` a `/oauth/register`:

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

## 2. Genere un desafío de código PKCE

Antes de redirigir al usuario, genere un verificador y un desafío de código PKCE:

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

## 3. Redirija al usuario a Glossia

Cree la URL de autorización y redirija el navegador del usuario:

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
|-----------|-------------|-------------|
| `response_type` | Sí | Siempre `code` |
| `client_id` | Sí | El ID de cliente de su aplicación |
| `redirect_uri` | Sí | Debe coincidir con una URL de devolución de llamada registrada |
| `code_challenge` | Sí | El desafío de código PKCE (S256) |
| `code_challenge_method` | Sí | Siempre `S256` |
| `scope` | No | Lista de [ámbitos](/docs/reference/apis/authentication) separados por espacios. Si se omite, se utiliza el acceso mínimo |
| `state` | Recomendado | Una cadena aleatoria para evitar ataques CSRF. Compruebe que coincida cuando el usuario regrese |

El usuario verá una pantalla de consentimiento con el nombre de su aplicación y los ámbitos solicitados. Tras aprobarlos, Glossia lo redirigirá a su URL de devolución de llamada con un código de autorización.

## 4. Intercambie el código por tokens

Cuando el usuario sea redirigido de nuevo a su URL de devolución de llamada, la URL contendrá un parámetro `code`:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

Primero, compruebe que `state` coincida con lo que envió en el paso 3. A continuación, intercambie el código por tokens:

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

Guarde ambos tokens de forma segura. El token de acceso se utiliza para las solicitudes a la API. El token de actualización se utiliza para obtener un nuevo token de acceso cuando caduque el actual.

## 5. Llame a la API en nombre del usuario

Utilice el token de acceso para realizar solicitudes autenticadas a la API:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

Los ámbitos del token limitan los puntos de conexión a los que puede acceder. La autorización a nivel de recurso sigue aplicándose. Por ejemplo, un token con `project:read` solo puede leer los proyectos a los que el usuario tenga acceso.

## 6. Actualice el token

Cuando caduque el token de acceso, utilice el token de actualización para obtener uno nuevo sin volver a enviar al usuario por el flujo de consentimiento:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. Revoque un token

Cuando un usuario desconecte su aplicación o ya no necesite acceso, revoque el token:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## Selección de ámbitos

Solicite únicamente los ámbitos que necesite su aplicación. Estas son algunas combinaciones habituales:

| Caso de uso | Ámbitos |
|-------------|---------|
| Leer el perfil del usuario | `user:read` |
| Leer proyectos y contenido | `user:read project:read voice:read` |
| Gestionar proyectos | `user:read project:read project:write` |
| Acceso completo a la organización | `user:read organization:read organization:write members:read members:write project:read project:write` |

Consulte la [referencia completa de ámbitos](/docs/reference/apis/authentication) para conocer todos los ámbitos disponibles.

## Endpoints de descubrimiento

Su aplicación puede descubrir automáticamente los endpoints de OAuth obteniendo los metadatos del servidor:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

Esto devuelve un documento JSON con `authorization_endpoint`, `token_endpoint`, `revocation_endpoint` y otros detalles. El uso del descubrimiento hace que su integración sea resistente a cambios en los endpoints.

## Gestión de errores

### Errores de autorización

Si el usuario rechaza el consentimiento o se produce algún problema durante la autorización, Glossia redirige a su URL de callback con un parámetro `error`:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

Códigos de error habituales:

| Error | Significado |
|-------|-------------|
| `access_denied` | El usuario rechazó la solicitud de autorización |
| `invalid_request` | Falta un parámetro obligatorio en la solicitud |
| `invalid_scope` | Uno o varios de los ámbitos solicitados no son válidos |

### Errores de token

El endpoint de token devuelve HTTP 400 con un cuerpo de error JSON:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### Límites de solicitudes

Los endpoints de OAuth tienen límites de solicitudes por dirección IP. Si alcanza el límite, recibirá HTTP 429. Consulte la [referencia sobre límites de solicitudes](/docs/reference/apis/authentication) para obtener más información.

## Lista de comprobación de seguridad

Antes de pasar a producción, compruebe que su implementación siga estas prácticas:

- Use siempre HTTPS para las URL de callback en producción
- Valide el parámetro `state` en el callback para evitar ataques CSRF
- Almacene los tokens cifrados en reposo
- Nunca exponga tokens en JavaScript del lado del cliente ni en URL del navegador
- Use el conjunto mínimo de ámbitos necesarios
- Gestione correctamente la expiración de los tokens mediante tokens de actualización
- Revoque los tokens cuando los usuarios se desconecten o eliminen su cuenta