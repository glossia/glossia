%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "referencia",
  subcategory: "apis",
  order: 3
}
---
Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines de CI/CD y automatización personal.

## Crear un token

1. Inicia sesión en Glossia y navega al panel de tu cuenta.
2. Abre la **API** sección desde la barra lateral.
3. Haz clic **Tokens de cuenta**, luego **Nuevo token**.
4. Asigna al token un nombre descriptivo **nombre** (por ejemplo, "CI deploy" o "CLI access").
5. Elige los **alcances** los que necesita el token. Solo otorgue los permisos mínimos requeridos.
6. Establezca una **fecha de caducidad** o déjelo en blanco para un token que nunca caduca.
7. Haga clic **Crear token**.

Tras la creación, se muestra el valor completo del token. **una sola vez**. Cópialo inmediatamente y guárdalo de forma segura. No podrás ver el valor completo de nuevo.

## Uso de un token

Incluye el token en el `Authorization` encabezado de tus solicitudes HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authorization) como tokens OAuth. Los alcances del token definen el conjunto máximo de acciones que puede realizar, y las políticas a nivel de recurso siguen aplicándose según las relaciones de tu cuenta.

## Formato de token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo facilita identificar los tokens de Glossia en los registros y escáneres de secretos.

## Alcances

Los tokens de cuenta soportan los mismos alcances que los tokens OAuth. Consulta el [referencia de alcances](/docs/reference/apis/authorization) para la lista completa.

Al crear un token, seleccione solo los alcances que su caso de uso requiere. Por ejemplo:

- Una integración de solo lectura requiere `project:read` y `voice:read`.
- Un pipeline CI que crea proyectos requiere `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualización de tokens

El **Tokens de cuenta** la página lista todos los tokens activos con su nombre, ámbitos, fecha de último uso y vencimiento. Los tokens que nunca han sido utilizados muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haz clic en el nombre de un token para editar su **nombre** y **descripción**. Los ámbitos y la caducidad no pueden cambiarse después de la creación. Si necesitas diferentes ámbitos, crea un nuevo token y revoca el antiguo.

### Revocación de tokens

Para revocar un token, haz clic **Revocar** en la lista de tokens o abra la página de edición del token y utilice el **Revocar token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no se pueden restaurar.

## Mejores prácticas de seguridad

- **Almacene los tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca cometa tokens al control de código fuente.
- **Utilice tokens de corta duración.** Establecer una fecha de caducidad siempre que sea posible.
- **Minimizar los alcances.** Conceder solo los permisos que el token realmente necesita.
- **Rotar periódicamente.** Crear nuevos tokens y revocar los antiguos de forma programada.
- **Supervisar el uso.** Comprobar la fecha de "último uso" periódicamente. Revocar los tokens que ya no se utilizan.
- **Utilizar un token por integración.** De esta manera, revocar un token no afecta otros flujos de trabajo.

## Gestión de APIs

También puedes gestionar los tokens de la cuenta a través del REST API y del servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la API REST.