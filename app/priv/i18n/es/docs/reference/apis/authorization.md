%{
  title: "Autorización",
  summary:
    "Alcances de permisos, roles de organización y verificaciones de acceso a nivel de recurso.",
  category: "referencia",
  subcategory: "APIs",
  order: 2
}
---

La autenticación establece una identidad; la autorización decide qué acciones puede realizar dicha identidad. Consulte [Autenticación](/docs/reference/apis/authentication) para los flujos de inicio de sesión y de tokens.

## Alcances

Los alcances controlan qué acciones puede realizar un token. Siguen el patrón `object:action`.

| Alcance | Descripción |
|-------|-------------|
| `admin:read` | Leer datos de administración de la plataforma (solo para administradores de la plataforma) |
| `admin:write` | Actualizar datos de administración de la plataforma (solo para administradores de la plataforma) |
| `ops:read` | Leer datos de operaciones de la plataforma (solo para administradores de la plataforma) |
| `user:read` | Leer información del perfil de usuario |
| `user:write` | Actualizar perfil de usuario |
| `account:read` | Listar cuentas de organización a las que puede acceder |
| `organization:read` | Leer detalles de la organización (y listar sus organizaciones) |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:claim` | Reclamar una organización |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Acciones administrativas de organización |
| `members:read` | Leer miembros de la organización e invitaciones |
| `members:write` | Gestionar miembros de la organización e invitaciones |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Acciones administrativas de proyecto |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer configuración de voz |
| `voice:write` | Crear o actualizar configuración de voz |
| `voice:admin` | Acciones administrativas de voz |
| `glossary:read` | Leer entradas del glosario |
| `glossary:write` | Crear o actualizar entradas del glosario |
| `glossary:admin` | Gestionar configuración del glosario |
| `discussion:read` | Leer discusiones |
| `discussion:write` | Crear o actualizar discusiones |
| `discussion:admin` | Acciones administrativas de discusión |
| `ticket:read` | Leer tickets |
| `ticket:write` | Crear o actualizar tickets |
| `ticket:admin` | Acciones administrativas de ticket |
| `llm_model:read` | Leer modelos de lenguaje de la cuenta |
| `llm_model:write` | Gestionar modelos de lenguaje de la cuenta |
| `translation:write` | Escribir datos de traducción |
| `api_credentials:read` | Leer credenciales de acceso |
| `api_credentials:write` | Gestionar credenciales de acceso |

Los [metadatos de descubrimiento](/docs/reference/apis/authentication#discovery-endpoints) del servidor de autenticación publican los alcances disponibles para los clientes. El hecho de que un alcance esté disponible no otorga acceso por sí solo.

## Modelo de autorización

Glossia **impone dos capas** para la [Transferencia de Estado Representativo](https://developer.mozilla.org/en-US/docs/Glossary/REST) de programación de aplicaciones y el [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io) de servidor:

1. **Verificación de alcance**: el token de acceso debe incluir el alcance `object:action` requerido.
2. **Política a nivel de recursos**: el usuario actual debe estar autorizado para el recurso específico a través de permisos explícitos de miembros o de la política basada en roles.

Los alcances representan la *máxima* capacidad de un token. Las comprobaciones a nivel de recurso aplican la *real* autorización para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización que posee el recurso |
| `organization_admin` | Un administrador de la organización que posee el recurso |
| `public_account` | El recurso pertenece a una cuenta pública |

### Permisos de miembros

Las afiliaciones de la organización no administradoras pueden contener alcances de permisos explícitos. Los nuevos miembros inician con acceso de lectura a la cuenta, organización, proyectos, voz, glosario, discusiones y tickets. Un administrador de la organización puede reemplazar esos alcances a través de [Miembros → Permisos](/docs/how-to/member-permissions). Una acción solicitada debe estar incluida en los alcances permitidos del miembro así como en los alcances del token al usar un token.

Los administradores de la organización conservan su rol de administrador. Las afiliaciones existentes sin alcances explícitos continúan utilizando la política basada en roles a continuación hasta que se guarden los permisos.

### Permisos de roles

La siguiente tabla muestra las reglas comunes basadas en roles para los miembros sin alcances explícitos. No es la política completa: las solicitudes de colección, el acceso temporal y los administradores de la plataforma tienen reglas adicionales.

| Alcance | Propio | Miembro de la organización | Administrador de la organización | Cuenta pública |
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
