%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines de CI/CD y automatización personal.

## Creando un token

1. Inicia sesión en Glossia y navega a tu panel de cuenta.
2. Abre el **API** sección de la barra lateral.
3. Haz clic **Tokens de cuenta**, luego **Nuevo token**.
4. Asigne al token un descriptivo **nombre** (por ejemplo, "CI deploy" o "CLI access").
5. Seleccione los **alcances** que el token necesita. Solo conceda los permisos mínimos requeridos.
6. Establezca una **fecha de expiración** o déjenlo en blanco para un token que nunca caducará.
7. Haga clic **Crear token**.

Después de la creación, se muestra el valor completo del token. **una vez**. Cópialo inmediatamente y guárdalo de forma segura. No podrás volver a ver el valor completo.

## Usando un token

Incluye el token en el `Authorization` encabezado de tus solicitudes HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) como tokens OAuth. Los ámbitos del token definen el conjunto máximo de acciones que puede realizar, y las políticas a nivel de recurso siguen aplicándose basándose en las relaciones de su cuenta.

## Formato de token

Todos los tokens de cuenta comienzan con el `glsa_` un prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo facilita identificar los tokens de Glossia en los registros y escáneres de secretos.

## Ámbitos

Los tokens de cuenta soportan los mismos ámbitos que los tokens OAuth. Consulte la [referencia de ámbitos](/docs/reference/apis/authentication) para la lista completa.

Al crear un token, selecciona solo los ámbitos que requiera tu caso de uso. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualización de tokens

La **Tokens de cuenta** página lista todos los tokens activos con su nombre, ámbitos, fecha de último uso y expiración. Los tokens que nunca se han utilizado muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haga clic en el nombre de un token para editar su **nombre** y **descripción**. Los alcances y la expiración no se pueden cambiar después de la creación. Si necesita diferentes alcances, cree un nuevo token y revoque el anterior.

### Revocación de tokens

Para revocar un token, haga clic **Revocar** en la lista de tokens o abra la página de edición del token y utilice el **Revocar token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no se pueden restaurar.

## Mejores prácticas de seguridad

- **Almacene tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca haga commit de tokens al control de versiones.
- **Utilice tokens de corta duración.** Establezca una fecha de caducidad siempre que sea posible.
- **Minimice los alcances.** Conceda solo los permisos que realmente necesita el token.
- **Rote regularmente.** Cree nuevos tokens y revoque los antiguos periódicamente.
- **Supervise el uso.** Revise periódicamente la fecha de "último uso". Revoque los tokens que ya no se utilizan.
- **Utilice un token por integración.** De esta manera, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puedes gestionar los tokens de la cuenta mediante la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la REST API.