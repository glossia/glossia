%{
  title: "Autorización",
  summary:
    "Alcance de permisos, roles de organización y comprobaciones de acceso a nivel de recurso.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---

La autenticación establece una identidad; la autorización decide qué acciones puede realizar esa identidad. Consulte [Autenticación](/docs/reference/apis/authentication) para los flujos de inicio de sesión y tokens.

## Alcances

Los alcances controlan qué acciones puede realizar un token. Siguen el `object:action` patrón.

| Alcance | Descripción |
|-------|-------------|
| `admin:read` | Leer datos de administración de la plataforma (solo administradores de la plataforma) |
| `admin:write` | Actualizar datos de administración de la plataforma (solo administradores de la plataforma) |
| `ops:read` | Leer datos de operaciones de la plataforma (solo administradores de la plataforma) |
| `user:read` | Leer información del perfil de usuario |
| `user:write` | Actualizar perfil de usuario |
| `account:read` | Listar cuentas de organización a las que pueda acceder |
| `organization:read` | Leer detalles de la organización (y listar sus organizaciones) |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:claim` | Reclamar una organización |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Acciones administrativas de la organización |
| `members:read` | Leer miembros de la organización y las invitaciones |
| `members:write` | Gestionar miembros de la organización y las invitaciones |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Acciones administrativas de los proyectos |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer configuración de voz |
| `voice:write` | Crear o actualizar configuración de voz |
| `voice:admin` | Acciones administrativas de voz |
| `glossary:read` | Leer entradas de glosario |
| `glossary:write` | Crear o actualizar entradas de glosario |
| `glossary:admin` | Gestionar configuraciones de glosario |
| `discussion:read` | Leer discusiones |
| `discussion:write` | Crear o actualizar discusiones |
| `discussion:admin` | Acciones administrativas de discusiones |
| `ticket:read` | Leer tickets |
| `ticket:write` | Crear o actualizar tickets |
| `ticket:admin` | Acciones administrativas de tickets |
| `llm_model:read` | Leer modelos de lenguaje de la cuenta |
| `llm_model:write` | Gestionar modelos de lenguaje de la cuenta |
| `translation:write` | Escribir datos de traducción |
| `api_credentials:read` | Leer credenciales de acceso |
| `api_credentials:write` | Gestionar credenciales de acceso |

Los metadatos de descubrimiento [del servidor de autenticación](/docs/reference/apis/authentication#discovery-endpoints) publican los alcances disponibles para los clientes. El hecho de que un alcance esté disponible no otorga acceso por sí mismo.

## Modelo de autorización

Glossia impone **dos capas** para la [Representational State Transfer](https://developer.mozilla.org/en-US/docs/Glossary/REST) interfaz de programación de aplicaciones y el servidor [Model Context Protocol](https://modelcontextprotocol.io):

1. **Verificación de alcance**: el token de acceso debe incluir el `object:action` alcance requerido.
2. **Política de nivel de recurso**: el usuario actual debe estar autorizado para el recurso específico mediante permisos de miembro explícitos o la política basada en roles.

Los alcances representan la capacidad *máxima* de un token. Las comprobaciones de nivel de recurso imponen el *permiso efectivo* para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización que posee el recurso |
| `organization_admin` | Un administrador de la organización que posee el recurso |
| `public_account` | El recurso pertenece a una cuenta pública |

### Permisos de miembros

Las pertenencias de la organización de no administradores pueden incluir alcances explícitos de permisos. Los nuevos miembros comienzan con acceso de lectura a la cuenta, organización, proyectos, voz, glosario, discusiones y tickets. Un administrador de la organización puede reemplazar esos alcances mediante [Members → Permissions](/docs/how-to/member-permissions). Una acción solicitada debe estar incluida tanto en los alcances permitidos del miembro como en los del token cuando se utilice un token.

Los administradores de la organización mantienen su rol de administrador. Las pertenencias existentes sin alcances explícitos siguen utilizando la política basada en roles a continuación hasta que se guarden los permisos.

### Permisos de roles

La tabla a continuación muestra reglas comunes basadas en roles para las pertenencias sin alcances explícitos. No es la política completa: las solicitudes de colección, el acceso temporal y los administradores de la plataforma tienen reglas adicionales.

| Alcance | Sí | Sí | Sí | Sí |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | Sí | Sí | | |
| `user:write` | Sí | | | |
| `account:read` | | Sí | Sí | Sí |
| `organization:read` | | Sí | Sí | |
| `organization:write` | | | Sí | |
| `organization:delete` | | | Sí | |
| `organization:admin` | | | Sí | |
| `members:read` | | Sí | Sí | |
| `members:write` | | | Sí | |
| `project:read` | | Sí | Sí | Sí |
| `project:write` | | | Sí | |
| `project:admin` | | | Sí | |
| `project:delete` | | | Sí | |
| `voice:read` | | Sí | Sí | Sí |
| `voice:write` | | | Sí | |
| `voice:admin` | | | Sí | |
| `glossary:read` | | Sí | Sí | |
| `glossary:write` | | | Sí | |
| `glossary:admin` | | | Sí | |
