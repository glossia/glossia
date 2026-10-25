%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "referencia",
  subcategory: "APIs",
  order: 3
}
---

Los tokens de cuenta ofrecen una manera simple de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, pipelines CI/CD y automatización personal.

## Creación de un token

1. Inicie sesión en Glossia y navegue a su panel de control de cuenta.
2. Abra la sección **API** desde la barra lateral.
3. Haga clic en **Tokens de cuenta**, luego en **Nuevo token**.
4. Asigne al token un **nombre** descriptivo (por ejemplo, "CI deploy" o "CLI access").
5. Seleccione los **alcances** que necesita el token. Solo conceda las permisiones mínimas requeridas.
6. Seleccione una **fecha de expiración** o déjelo en blanco para un token que nunca expira.
7. Haga clic en **Crear token**.

Después de la creación, se muestra el valor completo del token **una sola vez**. Copielo inmediatamente y guárdelo de forma segura. No podrá volver a ver el valor completo.

## Uso de un token

Incluya el token en la cabecera `Authorization` de sus solicitudes HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por ejemplo, usando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [método de autorización](/docs/reference/apis/authorization) que los tokens OAuth. Los alcances del token definen el conjunto máximo de acciones que puede realizar, y las políticas a nivel de recurso aún se aplican según las relaciones de su cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el prefijo `glsa_` seguido de una cadena hexadecimal aleatoria. Este prefijo facilita la identificación de los tokens de Glossia en los registros y exploradores de secretos.

## Alcances

Los tokens de cuenta admiten los mismos alcances que los tokens OAuth. Consulte la [referencia de alcances](/docs/reference/apis/authorization) para obtener la lista completa.

Al crear un token, seleccione solo los alcances que requiere su caso de uso. Por ejemplo:

- Una integración solo lectura necesita `project:read` y `voice:read`.
- Un pipeline CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que gestiona los miembros de la organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Visualización de tokens

La página **Tokens de cuenta** lista todos los tokens activos con su nombre, alcances, fecha de último uso y caducidad. Los tokens que nunca se han utilizado muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haga clic en el nombre de un token para editar su **nombre** y **descripción**. Los alcances y la fecha de expiración no se pueden cambiar después de la creación. Si necesita alcances diferentes, cree un nuevo token y revoque el anterior.

### Revocación de tokens

Para revocar un token, haga clic en **Revocar** en la lista de tokens o abra la página de edición del token y utilice el botón **Revocar token** en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no pueden ser restaurados.

## Mejores prácticas de seguridad

- **Almacene los tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca registre tokens en control de código fuente.
- **Utilice tokens de vida corta.** Establezca una fecha de expiración siempre que sea posible.
- **Minimice los alcances.** Conceda solo las permisiones que el token realmente necesita.
- **Rotación periódica.** Cree nuevos tokens y revoque los antiguos según un horario.
- **Monitoree el uso.** Verifique la fecha de "último uso" periódicamente. Revoque los tokens que ya no se utilizan.
- **Utilice un token por integración.** De esta manera, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puede gestionar los tokens de cuenta a través de la API REST y el servidor MCP.

### REST API

| Método | Punto final | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone `list_tokens`, `create_token` y `revoke_token` herramientas que reflejan la REST API.
