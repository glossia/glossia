%{
  title: "Autenticación",
  summary:
    "Inicio de sesión en el navegador, tokens de acceso y puntos finales de autenticación.",
  category: "Referencia",
  subcategory: "APIs",
  order: 1
}
---

Esta página describe [Autorización Abierta](https://oauth.net/2.1/) (OAuth), [Intercambio de Clave de Prueba para el Código](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) y la [interfaz de programación de aplicaciones](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Las especificaciones de protocolo vinculadas a continuación se publican como Solicitudes para Comentarios (RFCs).

## Métodos de autenticación

Glossia soporta sesiones de navegador y tokens portadores. Los tokens portadores se pueden emitir a través del flujo de autorización a continuación o se pueden crear como [tokens de cuenta](/docs/reference/apis/account-tokens).

### Sesiones de navegador

Cuando inicia sesión a través de la interfaz de la web, Glossia utiliza autenticación basada en sesiones. Se autentifica mediante GitHub, GitLab, Google o un proveedor de identidad de organización configurado mediante la [biblioteca Assent](https://github.com/pow-auth/assent). Después de un inicio de sesión exitoso, se establece una cookie de sesión y se usa para solicitudes subsiguientes.

Las organizaciones pueden configurar Google Workspace o Okta y verificar su dominio de correo electrónico del trabajo antes de permitir la inscripción automática. Consulte [Configurar inicio de sesión de organización](/docs/how-to/organization-sign-in) para los requisitos de configuración y vinculación de cuentas.

### Tokens portadores (OAuth 2.1)

Para el acceso a la API (tal como desde la CLI u otras herramientas), Glossia implementa OAuth 2.1 con el flujo de código de autorización y PKCE. Los clientes obtienen un token portador e incluyen en el `Authorization` encabezado:

```
Authorization: Bearer <access_token>
```

## Flujo de OAuth 2.1

### 1. Registro dinámico de cliente

Los clientes se registran a sí mismos llamando a `POST /oauth/register` con sus metadatos. Esto sigue [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia devuelve `client_id` y `client_secret`. El redireccionamiento `localhost` en este ejemplo pertenece a su aplicación durante el desarrollo. Las aplicaciones de producción deben registrar su propia dirección segura de callback.

### 2. Solicitud de autorización

El cliente redirige al usuario a `/oauth/authorize` con parámetros PKCE:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE es requerido para todos los clientes.** Solo se admite el método de desafío `S256`.

### 3. Intercambio de tokens

Después de que el usuario aprueba, el cliente intercambia el código de autorización por tokens a `POST /oauth/token`:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

La respuesta incluye un token de acceso y opcionalmente un token de actualización.

### 4. Renovación de tokens

Cuando un token de acceso expira, use el token de actualización:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Consulte [Autorización](/docs/reference/apis/authorization) para los alcances de permiso, acceso de miembros y comprobación de nivel de recurso.

## Puntos finales de descubrimiento

Glossia publica metadatos en URL estándar bien conocidas para que los clientes puedan descubrir puntos finales automáticamente.

### Metadatos del Servidor de Autorización OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Devuelve el emisor, puntos finales, alcances admitidos, tipos de concesión y métodos de desafío de código.

### Metadatos de Recursos Protegidos (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Devuelve el identificador de recurso, servidores de autorización, alcances admitidos y métodos portadores.

## Limitación de tasa

El registro está limitado por la dirección del cliente. Las solicitudes de token, revocación y exploración están limitadas tanto por la dirección del cliente como por el identificador del cliente:

| Endpoint | Límite |
|----------|-------|
| `POST /oauth/register` | 5 peticiones por minuto |
| `POST /oauth/token` | 30 peticiones por minuto |
| `POST /oauth/revoke` | 30 peticiones por minuto |
| `POST /oauth/introspect` | 30 peticiones por minuto |

Cuando se produce la limitación por tasa, el servidor devuelve HTTP 429 (Demasiadas peticiones).
