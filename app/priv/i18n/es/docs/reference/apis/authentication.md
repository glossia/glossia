%{
  title: "Autenticación",
  summary: "Inicio de sesión en el navegador, tokens de acceso y endpoints de autenticación.",
  category: "referencia",
  subcategory: "APIs",
  order: 1
}
---

Esta página describe [Autorización Abierta](https://oauth.net/2.1/) (OAuth), [Prueba de Clave para Intercambio de Códigos](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) y la [interfaz de programación de aplicaciones](https://developer.mozilla.org/en-US/docs/Glossary/API) (API). Las especificaciones del protocolo vinculadas a continuación se publican como Solicitud de Comentarios (RFCs).

## Métodos de autenticación

Glossia admite sesiones de navegador y tokens portador. Los tokens portador se pueden emitir a través del flujo de autorización descrito a continuación o crearse como [tokens de cuenta](/docs/reference/apis/account-tokens).

### Sesiones de navegador

Cuando se inicia sesión a través de la interfaz web, Glossia utiliza autenticación basada en sesiones. Se autentica a través de GitHub, GitLab, Google o un proveedor de identidad de organización configurado utilizando la biblioteca [Assent](https://github.com/pow-auth/assent). Después de un inicio de sesión exitoso, se establece una cookie de sesión y se utiliza para solicitudes posteriores.

Las organizaciones pueden configurar Google Workspace o Okta y verificar su dominio de correo electrónico de trabajo antes de permitir la inscripción automática. Consulte [Configurar el inicio de sesión de la organización](/docs/how-to/organization-sign-in) para los requisitos de configuración y vinculación de cuentas.

### Tokens portador (OAuth 2.1)

Para el acceso a la API (por ejemplo, desde la CLI u otras herramientas), Glossia implementa OAuth 2.1 con el flujo de código de autorización y PKCE. Los clientes obtienen un token portador y lo incluyen en el encabezado `Authorization`:

```
Authorization: Bearer <access_token>
```

## Flujo de OAuth 2.1

### 1. Registro dinámico del cliente

Los clientes se registran a sí mismos llamando `POST /oauth/register` con sus metadatos. Esto sigue [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia devuelve `client_id` y `client_secret`. La redirección `localhost` en este ejemplo pertenece a su aplicación durante el desarrollo. Las aplicaciones de producción deben registrar su propia dirección de retorno segura.

### 2. Solicitud de autorización

El cliente redirige al usuario a `/oauth/authorize` con parámetros PKCE:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE es obligatorio para todos los clientes.** Solo se admite el método de desafío `S256`.

### 3. Intercambio de tokens

Después de que el usuario aprueba, el cliente intercambia el código de autorización por tokens en `POST /oauth/token`:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

La respuesta incluye un token de acceso y opcionalmente un token de renovación.

### 4. Renovación de tokens

Cuando un token de acceso caduca, utilice el token de renovación:

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

Consulte [Autorización](/docs/reference/apis/authorization) para los ámbitos de permisos, acceso de miembros y verificaciones a nivel de recurso.

## Puntos finales de descubrimiento

Glossia publica metadatos en URLs bien conocidas estándar para que los clientes puedan descubrir puntos finales automáticamente.

### Metadatos del Servidor de Autorización OAuth (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

Devuelve el emisor, los puntos finales, los ámbitos admitidos, los tipos de concesión y los métodos de desafío de código.

### Metadatos de Recurso Protegido (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

Devuelve el identificador de recurso, servidores de autorización, ámbitos admitidos y métodos portador.

## Limitación de tasa

El registro está limitado por la dirección del cliente. Las solicitudes de token, revocación e introspección están limitadas tanto por la dirección del cliente como por el identificador del cliente:

| Punto final | Límite |
|----------|-------|
| `POST /oauth/register` | 5 solicitudes por minuto |
| `POST /oauth/token` | 30 solicitudes por minuto |
| `POST /oauth/revoke` | 30 solicitudes por minuto |
| `POST /oauth/introspect` | 30 solicitudes por minuto |

Cuando se aplica limitación de tasa, el servidor devuelve HTTP 429 (Demasiadas solicitudes).
