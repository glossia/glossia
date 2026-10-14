%{
  title: "Tokens de cuenta",
  summary: "Crea y gestiona tokens de cuenta para autenticarte con la API de Glossia.",
  category: "referencia",
  subcategory: "APIs",
  order: 3
}
---

Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, tuberías CI/CD y automatización personal.

## Creación de un token

1. Ingresa a Glossia y navega a tu panel de control de cuenta.
2. Abre la sección **API** del menú lateral.
3. Haz clic en **Account tokens**, luego en **New token**.
4. Asigna un **name** descriptivo al token (por ejemplo, "CI deploy" o "CLI access").
5. Elige los **scopes** que necesita el token. Solo otorga las permisos mínimos requeridos.
6. Establece una **expiration date** o déjalo vacío para un token que nunca caduca.
7. Haz clic en **Create token**.

Después de la creación, el valor completo del token se muestra **once**. Cópltalo inmediatamente y guárdalo de forma segura. No podrás ver el valor completo nuevamente.

## Uso de un token

Incluye el token en el `Authorization` encabezado de tus solicitudes HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por ejemplo, utilizando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [authorization model](/docs/reference/apis/authorization) que los tokens OAuth. Los scopes del token definen el conjunto máximo de acciones que puede realizar, y las políticas a nivel de recurso siguen aplicándose según las relaciones de tu cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el `glsa_` prefix seguido de una cadena hexadecimal aleatoria. Este preficio facilita identificar los tokens de Glossia en registros y detectores de secretos.

## Scopes

Los tokens de cuenta soportan los mismos scopes que los tokens OAuth. Consulta la [scopes reference](/docs/reference/apis/authorization) para la lista completa.

Al crear un token, selecciona solo los scopes que requiere tu caso de uso. Por ejemplo:

- Una integración solo de lectura necesita `project:read` y `voice:read`.
- Una tubería CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona miembros de organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualizar tokens

La página **Account tokens** lista todos los tokens activos con su nombre, scopes, fecha de último uso y caducidad. Los tokens que nunca se han usado muestran "Never" en la columna de último uso.

### Edición de tokens

Haz clic en el nombre de un token para editar su **name** y **description**. Los scopes y la caducidad no se pueden cambiar después de la creación. Si necesitas scopes diferentes, crea un token nuevo y revoca el antiguo.

### Revocación de tokens

Para revocar un token, haz clic en **Revoke** en la lista de tokens o abre la página de edición del token y usa el botón **Revoke token** en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no se pueden restaurar.

## Mejores prácticas de seguridad

- **Store tokens securely.** Usa variables de entorno o un administrador de secretos. Nunca cometes tokens al control de origen.
- **Use short-lived tokens.** Establece una fecha de caducidad siempre que sea posible.
- **Minimize scopes.** Otorga solo los permisos que el token necesita realmente.
- **Rotate regularly.** Crea tokens nuevos y revoca los antiguos según un cronograma.
- **Monitor usage.** Revisa la fecha de "last used" periódicamente. Revoca tokens que ya no se utilizan.
- **Use one token per integration.** De este modo, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puedes gestionar tokens de cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens activos |
| `POST` | `/api/tokens` | Crear un token nuevo |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone las herramientas `list_tokens`, `create_token` y `revoke_token` que replican la REST API.
