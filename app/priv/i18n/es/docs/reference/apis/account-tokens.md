%{
  title: "Tokens de cuenta",
  summary: "Cree y gestione tokens de cuenta para autenticarse con la API de Glossia.",
  category: "reference",
  subcategory: "apis",
  order: 2
}
---
Los tokens de cuenta ofrecen una forma sencilla de autenticar solicitudes de API sin pasar por el flujo completo de OAuth. Son ideales para scripts, canalizaciones de CI/CD y automatizaciones personales.

## Crear un token

1. Inicie sesión en Glossia y vaya al panel de su cuenta.
2. Abra la sección **API** desde la barra lateral.
3. Haga clic en **Tokens de cuenta** y, después, en **Nuevo token**.
4. Asigne al token un **nombre** descriptivo (por ejemplo, «Despliegue de CI» o «Acceso mediante CLI»).
5. Elija los **ámbitos** que necesita el token. Conceda únicamente los permisos mínimos necesarios.
6. Defina una **fecha de vencimiento** o déjela en blanco para crear un token que nunca venza.
7. Haga clic en **Crear token**.

Tras crearlo, el valor completo del token se muestra **una sola vez**. Cópielo de inmediato y guárdelo de forma segura. No podrá volver a ver el valor completo.

## Usar un token

Incluya el token en el encabezado `Authorization` de sus solicitudes HTTP:

```
Authorization: Bearer glsa_abc123def456...
```

Por ejemplo, con `curl`:

```bash
curl -H "Authorization: Bearer glsa_abc123def456..." \
  https://glossia.ai/api/projects
```

Los tokens de cuenta siguen el mismo [modelo de autorización](/docs/reference/apis/authentication) que los tokens de OAuth. Los ámbitos del token definen el conjunto máximo de acciones que puede realizar, y las políticas a nivel de recurso siguen aplicándose según las relaciones de su cuenta.

## Formato del token

Todos los tokens de cuenta comienzan con el prefijo `glsa_`, seguido de una cadena hexadecimal aleatoria. Este prefijo facilita la identificación de los tokens de Glossia en registros y analizadores de secretos.

## Ámbitos

Los tokens de cuenta admiten los mismos ámbitos que los tokens de OAuth. Consulte la [referencia de ámbitos](/docs/reference/apis/authentication) para ver la lista completa.

Al crear un token, seleccione únicamente los ámbitos que requiera su caso de uso. Por ejemplo:

- Una integración de solo lectura necesita `project:read` y `voice:read`.
- Una canalización de CI que crea proyectos necesita `project:read` y `project:write`.
- Un script que administra miembros de una organización necesita `members:read` y `members:write`.

## Administrar tokens

### Ver tokens

La página **Tokens de cuenta** muestra todos los tokens activos con su nombre, ámbitos, fecha del último uso y vencimiento. Los tokens que nunca se han utilizado muestran «Nunca» en la columna del último uso.

### Editar tokens

Haga clic en el nombre de un token para editar su **nombre** y **descripción**. Los ámbitos y el vencimiento no se pueden cambiar después de crear el token. Si necesita otros ámbitos, cree un token nuevo y revoque el anterior.

### Revocar tokens

Para revocar un token, haga clic en **Revocar** en la lista de tokens o abra la página de edición del token y utilice el botón **Revocar token** de la zona de peligro. Los tokens revocados dejan de funcionar de inmediato y no se pueden restaurar.

## Prácticas recomendadas de seguridad

- **Guarde los tokens de forma segura.** Utilice variables de entorno o un gestor de secretos. Nunca confirme tokens en el control de código fuente.
- **Utilice tokens de corta duración.** Defina una fecha de vencimiento siempre que sea posible.
- **Minimice los ámbitos.** Conceda únicamente los permisos que el token realmente necesita.
- **Rótelos periódicamente.** Cree tokens nuevos y revoque los antiguos de forma programada.
- **Supervise el uso.** Compruebe periódicamente la fecha del «último uso». Revoque los tokens que ya no se utilicen.
- **Utilice un token por integración.** De este modo, revocar un token no interrumpe otros flujos de trabajo.

## Administración mediante API

También puede administrar los tokens de cuenta mediante la API REST y el servidor MCP.

### API REST

| Método | Punto de conexión | Descripción |
|--------|----------|-------------|
| `GET` | `/api/tokens` | Mostrar los tokens activos |
| `POST` | `/api/tokens` | Crear un token nuevo |
| `DELETE` | `/api/tokens/:id` | Revocar un token |

### MCP

El servidor MCP expone las herramientas `list_tokens`, `create_token` y `revoke_token`, que replican la API REST.