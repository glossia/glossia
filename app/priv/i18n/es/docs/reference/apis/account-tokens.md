%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
Los tokens de cuenta proporcionan una forma sencilla de autenticar solicitudes de API sin necesidad de pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines CI/CD y automatización personal.

## Creación de un token

1. Inicia sesión en Glossia y ve a tu panel de la cuenta.
2. Abrir el **API** Sección de la barra lateral.
3. Hacer clic **Tokens de cuenta**, entonces **Nuevo token**.
4. Asigna al token un nombre **descriptivo** (por ejemplo, "CI deploy" o "CLI access").
5. Elige los **ámbitos** que necesita el token. Otorga solo los permisos mínimos requeridos.
6. Establece una **fecha de expiración** o déjalo en blanco para un token que nunca caducará.
7. Haz clic **Crear token**.

Después de la creación, se muestra el valor completo del token. **una vez**. Cópialo inmediatamente y guárdelo de forma segura. No podrá ver el valor completo nuevamente.

## Usando un token

Incluya el token en el `Authorization` encabezado de sus solicitudes HTTP:

    Authorization: Bearer glsa_abc123def456...

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) como tokens OAuth. Los ámbitos del token definen el conjunto máximo de acciones que puede realizar, y las políticas de nivel de recurso todavía se aplican basándose en las relaciones de tu cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo facilita la identificación de los tokens de Glossia en los registros y los escáneres de secretos.

## Ámbitos

Los tokens de cuenta admiten los mismos ámbitos que los tokens OAuth. Consulte la [referencia de ámbitos](/docs/reference/apis/authentication) para la lista completa.

Al crear un token, seleccione solo los alcances que requiere su caso de uso. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestionar tokens

### Visualizar tokens

La **Tokens de cuenta** página lista todos los tokens activos con su nombre, alcances, fecha de último uso y vencimiento. Los tokens que nunca se han usado muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haga clic en el nombre de un token para editar su **nombre** y **descripción**. Los alcances y la expiración no pueden cambiarse después de la creación. Si necesita diferentes alcances, cree un nuevo token y revoque el anterior.

### Revocación de tokens

Para revocar un token, haga clic **Revocar** en la lista de tokens o abre la página de edición del token y usa la **Revocar token** botón en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no se pueden restaurar.

## Mejores prácticas de seguridad

- **Almacena los tokens de forma segura.** Usa variables de entorno o un gestor de secretos. Nunca hagas commits de tokens en el control de versiones.
- **Usa tokens de corta duración.** Establezca una fecha de caducidad siempre que sea posible.
- **Minimice los alcances.** Conceda solo los permisos que el token realmente necesita.
- **Rota regularmente.** Cree tokens nuevos y revóque los antiguos según un cronograma.
- **Monitoree el uso.** Compruebe la fecha de \\"último uso\\" periódicamente. Revóque los tokens que ya no se usan.
- **Utilice un token por integración.** De este modo, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puede gestionar los tokens de cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Lista de tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token`, y `revoke_token` herramientas que reflejan la API REST.