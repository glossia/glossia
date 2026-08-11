%{
  title: "Autenticación y autorización",
  summary: "Cómo autentica Glossia a los usuarios y autoriza el acceso a la API.",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## Métodos de autenticación

Glossia admite dos métodos de autenticación según el contexto.

### Sesiones del navegador

Cuando inicia sesión a través de la interfaz web, Glossia utiliza autenticación basada en sesiones. La autenticación se realiza mediante un proveedor externo (GitHub o GitLab) utilizando la biblioteca [Assent](https://github.com/pow-auth/assent). Tras iniciar sesión correctamente, se establece una cookie de sesión que se utiliza en las solicitudes posteriores.

### Tokens Bearer (OAuth 2.1)

Para acceder a la API, por ejemplo desde la CLI u otras herramientas, Glossia implementa OAuth 2.1 con el flujo de código de autorización y PKCE. Los clientes obtienen un token Bearer y lo incluyen en la cabecera `Authorization`:

```
Authorization: Bearer <access_token>
```

## Flujo de OAuth 2.1

### 1. Registro dinámico de clientes

Los clientes se registran llamando a `POST /oauth/register` con sus metadatos. Este proceso sigue la [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

El servidor devuelve `client_id` y `client_secret`.

### 2. Solicitud de autorización

El cliente redirige al usuario a `/oauth/authorize` con los parámetros de PKCE:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE es obligatorio para todos los clientes.** Solo se admite el método de desafío `S256`.

### 3. Intercambio de tokens

Una vez que el usuario concede la autorización, el cliente intercambia el código de autorización por tokens en `POST /oauth/token`:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

La respuesta incluye un token de acceso y, opcionalmente, un token de actualización.

### 4. Actualización del token

Cuando caduca un token de acceso, utilice el token de actualización:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## Ámbitos

Los ámbitos controlan qué acciones puede realizar un token. Siguen el patrón `object:action`.

| Ámbito | Descripción |
|-------|-------------|
| `user:read` | Leer la información del perfil del usuario |
| `user:write` | Actualizar el perfil del usuario |
| `account:read` | Enumerar las cuentas de organizaciones a las que puede acceder |
| `organization:read` | Leer los detalles de organizaciones y enumerar sus organizaciones |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Realizar acciones administrativas en organizaciones |
| `members:read` | Leer los miembros y las invitaciones de organizaciones |
| `members:write` | Gestionar los miembros y las invitaciones de organizaciones |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Realizar acciones administrativas en proyectos |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer la configuración de voz |
| `voice:write` | Crear o actualizar la configuración de voz |
| `voice:admin` | Realizar acciones administrativas relacionadas con la voz |
| `glossary:read` | Leer las entradas de terminologia |
| `glossary:write` | Crear o actualizar entradas de terminologia |
| `glossary:admin` | Gestionar la configuración de terminologia |

## Modelo de autorización

Glossia aplica **dos capas** para la API REST y el servidor MCP:

1. **Comprobación del ámbito**: el token de acceso debe incluir el ámbito `object:action` requerido.
2. **Política a nivel de recurso**: el usuario actual debe tener autorización para el recurso específico mediante `Glossia.Policy`.

Los ámbitos representan la capacidad *máxima* de un token. El sistema de políticas aplica el permiso *real* para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización propietaria del recurso |
| `organization_admin` | Un administrador de la organización propietaria del recurso |
| `public_account` | La cuenta es pública (solo lectura) |

### Permisos de los roles

| Ámbito | self | organization_member | organization_admin | public_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Sí | Sí | | |
| `user:write` | Sí | | | |
| `account:read` | | Sí | Sí | Sí |
| `organization:read` | | Sí | Sí | |
| `organization:write` | | | Sí | |
| `organization:delete` | | | Sí | |
| `organization:admin` | | | Sí | |
| `members:read` | | Sí | Sí | |
| `members:write` | | | Sí | |
| `project:read` | | Sí | Sí | Sí |
| `project:write` | | | Sí | |
| `project:admin` | | | Sí | |
| `project:delete` | | | Sí | |
| `voice:read` | | Sí | Sí | Sí |
| `voice:write` | | | Sí | |
| `voice:admin` | | | Sí | |
| `glossary:read` | | Sí | Sí | |
| `glossary:write` | | | Sí | |
| `glossary:admin` | | | Sí | |

## Puntos de conexión de descubrimiento

Glossia publica metadatos en direcciones URL estándar conocidas para que los clientes puedan descubrir automáticamente los puntos de conexión.

### Metadatos del servidor de autorización OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Devuelve el emisor, los puntos de conexión, los ámbitos admitidos, los tipos de concesión y los métodos de desafío de código.

### Metadatos del recurso protegido (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Devuelve el identificador del recurso, los servidores de autorización, los ámbitos admitidos y los métodos de portador.

## Limitación de solicitudes

Los puntos de conexión OAuth están sujetos a límites de solicitudes por dirección IP:

| Punto de conexión | Límite |
|----------|-------|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |

Cuando se supera el límite de solicitudes, el servidor devuelve HTTP 429 (Demasiadas solicitudes).