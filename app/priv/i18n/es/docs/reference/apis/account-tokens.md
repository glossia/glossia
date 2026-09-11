%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
Tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines de CI/CD y automatización personal.

## Creación de un token

1. Inicia sesión en Glossia y navega a tu panel de cuenta.
2. Abre la **API** sección desde la barra lateral.
3. Haz clic **Tokens de cuenta**, entonces **Nuevo token**.
4. Asigne al token un nombre descriptivo **nombre** (por ejemplo, "CI deploy" o "CLI access").
5. Elija los **alcances** los que necesita el token. Otorgue solo los permisos mínimos requeridos.
6. Establezca un **fecha de caducidad** o déjelo vacío para un token que nunca expira.
7. Haga clic **Crear token**.

Tras la creación, se muestra el valor completo del token. **una vez**. Cópialo inmediatamente y guárdalo de forma segura. No podrás ver el valor completo de nuevo.

## Usando un token

Incluye el token en el `Authorization` encabezado de tus solicitudes HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) como tokens OAuth. Los alcances del token definen el conjunto máximo de acciones que puede realizar, y las políticas de nivel de recurso siguen aplicándose basándose en las relaciones de su cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo facilita identificar los tokens de Glossia en los registros y escáneres de secretos.

## Alcances

Los tokens de cuenta soportan los mismos alcances que los tokens OAuth. Ve la [referencia de alcances](/docs/reference/apis/authentication) para la lista completa.

Al crear un token, seleccione solo los alcances que requiere su caso de uso. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestionar tokens

### Ver tokens

La **Tokens de cuenta** página lista todos los tokens activos con su nombre, alcances, fecha de último uso y expiración. Los tokens que nunca se han utilizado muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haga clic en el nombre de un token para editar su **nombre** y **descripción**. Los ámbitos y la caducidad no se pueden cambiar después de la creación. Si necesitas diferentes ámbitos, crea un nuevo token y revoca el antiguo.

### Revocación de tokens

Para revocar un token, haz clic **Revocar** en la lista de tokens o abra la página de edición del token y utilice el **Revocar el token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no pueden ser restaurados.

## Mejores prácticas de seguridad

- **Almacene tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca cometa tokens al control de versiones.
- **Utilice tokens de corta duración.** Establece una fecha de expiración siempre que sea posible.
- **Minimiza los ámbitos.** Concede solo los permisos que realmente necesita el token.
- **Rota regularmente.** Crea nuevos tokens y revoca los antiguos de forma programada.
- **Supervisa el uso.** Verifica la fecha de "último uso" periódicamente. Revoca los tokens que ya no se utilizan.
- **Usa un token por integración.** De esta manera, revocar un token no afecta otros flujos de trabajo.

## Gestión de API

También puede gestionar los tokens de la cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la API REST.