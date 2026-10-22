%{
  title: "Tokens de cuenta",
  summary: "Crear y gestionar tokens de cuenta para autenticarse con la API de Glossia.",
  category: "Referencia",
  subcategory: "APIs",
  order: 3
}
---

Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por todo el flujo de OAuth. Son ideales para guiones, pipelines de CI/CD y automatización personal.

## Creación de un token

1. Inicie sesión en Glossia y navegue al panel de su cuenta.
2. Abra la sección **API** de la barra lateral.
3. Haga clic en **Tokens de cuenta** y luego en **Nuevo token**.
4. Asigne un **nombre** descriptivo al token (por ejemplo, "CI deploy" o "Acceso CLI").
5. Seleccione los **alcances** que necesita el token. Solo conceda los permisos mínimos requeridos.
6. Establezca una **fecha de caducidad** o déjelo en blanco para un token que nunca expira.
7. Haga clic en **Crear token**.

Tras la creación, se muestra el valor completo del token **una sola vez**. Copiérelo inmediatamente y guárdelo de forma segura. No podrá ver el valor completo nuevamente.

## Uso de un token

Incluya el token en el `Authorization` encabezado de sus solicitudes HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por ejemplo, utilizando `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authorization) que los tokens OAuth. Los alcances del token definen el conjunto máximo de acciones que puede realizar y las políticas a nivel de recurso continúan aplicándose basándose en las relaciones de su cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el `glsa_` prefijo seguido de una cadena hexadecimal aleatoria. Este prefijo hace que sea fácil identificar los tokens de Glossia en los registros y analizadores de secreto.

## Alcances

Los tokens de cuenta admiten los mismos alcances que los tokens OAuth. Consulte la [referencia de alcances](/docs/reference/apis/authorization) para la lista completa.

Al crear un token, seleccione solo los alcances que requiere su caso de uso. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Un pipeline de CI que crea proyectos necesita `project:read` y `project:write`.
- Un guión que administra miembros de organización necesita `members:read` y `members:write`.

## Gestión de tokens

### Vistas de tokens

La página **Tokens de cuenta** enumera todos los tokens activos con su nombre, alcances, fecha de último uso y caducidad. Los tokens que nunca han sido utilizados muestran "Nunca" en la columna de último uso.

### Edición de tokens

Haga clic en el nombre de un token para editar su **nombre** y **descripción**. Los alcances y la caducidad no pueden modificarse tras la creación. Si necesita alcances diferentes, cree un nuevo token y revogue el anterior.

### Revocación de tokens

Para revocar un token, haga clic en **Revocar** en la lista de tokens o abra la página de edición del token y use el botón **Revocar token** en la zona de peligro. Los tokens revocados dejan de funcionar inmediatamente y no pueden restaurarse.

## Mejores prácticas de seguridad

- **Almacene los tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca comprometa tokens en el control de versiones.
- **Utilice tokens de vida corta.** Establezca una fecha de caducidad en la medida de lo posible.
- **Minimice los alcances.** Conceda solo los permisos que el token necesita realmente.
- **Gire periódicamente.** Cree nuevos tokens y revogue los anteriores según un calendario.
- **Supervise el uso.** Revise la fecha de "último uso" periódicamente. Revogue los tokens que ya no se utilizan.
- **Utilice un token por integración.** De esta manera, revocar un token no rompe otros flujos de trabajo.

## Gestión de API

También puede gestionar los tokens de cuenta a través de la REST API y el servidor MCP.

### REST API

| Método | Punto de conexión | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Listar tokens activos |
| `POST` | `/api/tokens` | Crear un nuevo token |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone herramientas `list_tokens`, `create_token` y `revoke_token` que reflejan la REST API.
