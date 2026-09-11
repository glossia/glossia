%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines CI/CD y automatización personal.

## Crear un token

1. Inicia sesión en Glossia y navega a tu panel de cuenta.
2. Abre la **API** sección desde la barra lateral.
3. Haz clic **Tokens de cuenta**, entonces **Nuevo token**.
4. Asigne al token un nombre descriptivo **nombre** (por ejemplo, "CI deploy" o "CLI access").
5. Seleccione los **alcances** que necesita el token. Solo conceda los permisos mínimos requeridos.
6. Establezca una **fecha de expiración** o déjelo en blanco para un token que nunca caduca.
7. Haga clic **Crear token**.

Después de la creación, se muestra el valor completo del token **una vez**. Cópialo inmediatamente y guárdalo de forma segura. No podrás ver el valor completo nuevamente.

## Usar un token

Incluye el token en el `Authorization` cabecera de tus solicitudes HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) como tokens OAuth. Los alcances del token definen el conjunto máximo de acciones que puede realizar y las políticas de nivel de recurso siguen aplicándose basándose en las relaciones de tu cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo facilita la identificación de los tokens de Glossia en los registros y escáneres de secretos.

## Alcances

Los tokens de cuenta admiten los mismos alcances que los tokens OAuth. Consulta la [referencia de alcances](/docs/reference/apis/authentication) para la lista completa.

Al crear un token, seleccione solo los alcances que su caso de uso requiere. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona miembros de la organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualización de tokens

El **Tokens de cuenta** página enumera todos los tokens activos con su nombre, alcances, fecha de última vez usada y expiración. Los tokens que nunca han sido utilizados muestran "Nunca" en la columna de última vez usada.

### Edición de tokens

Haz clic en el nombre de un token para editar su **nombre** y **descripción**. Los ámbitos y la caducidad no pueden cambiarse después de la creación. Si necesitas ámbitos diferentes, crea un nuevo token y revoca el anterior.

### Revocación de tokens

Para revocar un token, haz clic en **Revocar** en la lista de tokens o abra la página de edición del token y utilice el **Revocar token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no se pueden restaurar.

## Mejores prácticas de seguridad

- **Almacene tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca envíe tokens al control de código fuente.
- **Utilice tokens de corta duración.** Establezca una fecha de expiración siempre que sea posible.
- **Minimice los alcances.** Conceda solo los permisos que realmente necesita el token.
- **Rota con regularidad.** Cree nuevos tokens y cancele los antiguos según un calendario.
- **Supervise el uso.** Revise la fecha "último uso" periódicamente. Revogue los tokens que ya no se usan.
- **Utilice un token por integración.** De este modo, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puedes gestionar los tokens de la cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la API REST.