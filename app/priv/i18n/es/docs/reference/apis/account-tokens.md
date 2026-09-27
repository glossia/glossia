%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines CI/CD y automatización personal.

## Creación de un token

1. Inicia sesión en Glossia y navega hasta tu panel de cuenta.
2. Abre la **API** sección de la barra lateral.
3. Haz clic en **Tokens de cuenta**, entonces **Nuevo token**.
4. Asigne al token un nombre descriptivo **nombre** (por ejemplo, \\"CI deploy\\" o \\"CLI access\\").
5. Elija los **alcances** que el token necesita. Solo conceda los permisos mínimos requeridos.
6. Establezca una **fecha de expiración** o déjelo en blanco para un token que nunca expira.
7. Haga clic **Crear token**.

Después de la creación, se muestra el valor completo del token. **una vez**. Cópialo inmediatamente y guárdalo de forma segura. No podrás ver el valor completo nuevamente.

## Usando un token

Incluye el token en el `Authorization` encabezado de tus peticiones HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) como tokens de OAuth. Los ámbitos del token definen el conjunto máximo de acciones que puede realizar, y las políticas a nivel de recurso siguen aplicándose según las relaciones de su cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido por una cadena hexadecimal aleatoria. Este prefijo facilita identificar los tokens de Glossia en los registros y escáneres de secretos.

## Ámbitos

Los tokens de cuenta admiten los mismos ámbitos que los tokens de OAuth. Consulte la [referencia de ámbitos](/docs/reference/apis/authentication) para la lista completa.

Al crear un token, seleccione solo los ámbitos que requiere su caso de uso. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualización de tokens

El **Tokens de la cuenta** la página enumera todos los tokens activos con su nombre, ámbitos, fecha de último uso y vencimiento. Los tokens que nunca se han utilizado muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haz clic en el nombre de un token para editar su **nombre** y **descripción**. Los alcances y la caducidad no pueden modificarse tras la creación. Si necesitas diferentes alcances, crea un nuevo token y revoca el anterior.

### Revocación de tokens

Para revocar un token, haz clic **Revocar** en la lista de tokens o abra la página de edición del token y utilice el **Revocar token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no pueden restaurarse.

## Mejores prácticas de seguridad

- **Almacene los tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca cometa tokens al control de versiones.
- **Utilice tokens de vida corta.** Fije una fecha de caducidad siempre que sea posible.
- **Minimice los alcances.** Otorgue solo los permisos que el token realmente necesite.
- **Rota regularmente.** Cree nuevos tokens y revoque los antiguos periódicamente.
- **Monitoree el uso.** Compruebe la fecha "último uso" periódicamente. Revóque los tokens que ya no se utilicen.
- **Utilice un token por integración.** De esta forma, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puede gestionar los tokens de la cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Lista de tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la REST API.