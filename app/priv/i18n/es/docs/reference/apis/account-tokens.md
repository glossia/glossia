%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines de CI/CD y automatización personal.

## Creación de un token

1. Inicia sesión en Glossia y navega a tu panel de cuenta.
2. Abre el **API** sección desde la barra lateral.
3. Haz clic **Tokens de cuenta**luego **Nuevo token**.
4. Asigna un nombre descriptivo al token **Nombre** (por ejemplo, "CI deploy" o "CLI access").
5. Elige los **alcances** que el token necesita. Solo otorgue los permisos mínimos requeridos.
6. Establezca una **fecha de expiración** o déjelo en blanco para un token que nunca caduca.
7. Haga clic **Crear token**.

Después de la creación, se muestra el valor completo del token. **una vez**. Cópialo inmediatamente y guárdalo de forma segura. No podrás ver el valor completo de nuevo.

## Usando un token

Incluye el token en el `Authorization` encabezado de tus peticiones HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) como tokens OAuth. Los alcances del token definen el conjunto máximo de acciones que puede realizar, y las políticas de nivel de recurso siguen aplicándose según las relaciones de tu cuenta.

## Formato de token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo facilita identificar los tokens de Glossia en los registros y los escáneres de secretos.

## Alcances

Los tokens de cuenta soportan los mismos alcances que los tokens OAuth. Consulta la [referencia de alcances](/docs/reference/apis/authentication) para la lista completa.

Al crear un token, seleccione solo los alcances que su caso de uso requiere. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualización de tokens

La **Tokens de cuenta** página lista todos los tokens activos con su nombre, alcances, fecha de último uso y expiración. Los tokens que nunca se han utilizado muestran \\"Nunca\\" en la columna de último uso.

### Edición de tokens

Haz clic en el nombre de un token para editar su **nombre** y **descripción**. El alcance y la expiración no pueden modificarse después de la creación. Si necesitas diferentes alcances, crea un nuevo token y revoca el antiguo.

### Revocación de tokens

Para revocar un token, haz clic **Revocar** en la lista de tokens o abre la página de edición del token y usa el **Revocar el token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no pueden ser restaurados.

## Mejores prácticas de seguridad

- **Almacena los tokens de forma segura.** Usa variables de entorno o un gestor de secretos. Nunca guardes tokens en el control de versiones.
- **Usa tokens de corta duración.** Establezca una fecha de caducidad siempre que sea posible.
- **Minimice los alcances.** Otorgue solo los permisos que el token realmente necesita.
- **Rote con regularidad.** Cree nuevos tokens y revogue los antiguos siguiendo un cronograma.
- **Monitoree el uso.** Verifique la fecha "último uso" periódicamente. Revogue los tokens que ya no estén en uso.
- **Utilice un token por integración.** De esta manera, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puedes gestionar los tokens de la cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` Listar tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la API REST.