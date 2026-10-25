%{
  title: "Autorización",
  summary:
    "Ámbitos de permisos, roles de organización y comprobaciones de acceso a nivel de recurso.",
  category: "referencia",
  subcategory: "APIs",
  order: 2
}
---

La autenticación establece una identidad; la autorización decide qué acciones puede realizar esa identidad. Ver [Autenticación](/docs/reference/apis/authentication) para los flujos de inicio de sesión y de token.

## ## Alcances

Los alcances controlan qué acciones puede realizar un token. Siguen el `object:action` patrón.

| Alcance | Descripción |
|-------|-------------|
| `admin:read` | Leer datos de administración de la plataforma (solo administradores de la plataforma) |
| `admin:write` | Actualizar datos de administración de la plataforma (solo administradores de la plataforma) |
| `ops:read` | Leer datos de operaciones de la plataforma (solo administradores de la plataforma) |
| `user:read` | Leer información del perfil de usuario |
| `user:write` | Actualizar perfil de usuario |
| `account:read` | Listar cuentas de organización a las que tiene acceso |
| `organization:read` | Leer detalles de la organización (y listar sus organizaciones) |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:claim` | Reivindicar una organización |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Acciones administrativas de organización |
| `members:read` | Leer miembros de la organización y invitaciones |
| `members:write` | Gestionar miembros de la organización y invitaciones |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Acciones administrativas de proyecto |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer configuración de voz |
| `voice:write` | Crear o actualizar configuración de voz |
| `voice:admin` | Acciones administrativas de voz |
| `glossary:read` | Leer entradas de glosario |
| `glossary:write` | Crear o actualizar entradas de glosario |
| `glossary:admin` | Gestionar configuraciones de glosario |
| `discussion:read` | Leer discusiones |
| `discussion:write` | Crear o actualizar discusiones |
| `discussion:admin` | Acciones administrativas de discusión |
| `ticket:read` | Leer tickets |
| `ticket:write` | Crear o actualizar tickets |
| `ticket:admin` | Acciones administrativas de ticket |
| `llm_model:read` | Leer modelos de lenguaje de la cuenta |
| `llm_model:write` | Gestionar modelos de lenguaje de la cuenta |
| `translation:read` | Leer actividad de traducción del proyecto |
| `translation:write` | Escribir datos de traducción |
| `analytics:read` | Leer análisis web del proyecto |
| `toki:read` | Leer sus propias conversaciones privadas del proyecto |
| `toki:write` | Crear conversaciones privadas y colar respuestas de compañero |
| `api_credentials:read` | Leer credenciales de acceso |
| `api_credentials:write` | Gestionar credenciales de acceso |

Los metadatos de [descubrimiento](/docs/reference/apis/authentication#discovery-endpoints) del servidor de autenticación publican los alcances disponibles para los clientes. Que un alcance esté disponible no otorga acceso por sí solo.

## Modelo de autorización

Glossia impone **dos capas** para la interfaz de programación de aplicaciones [Transferencia de Estado Representacional](https://developer.mozilla.org/en-US/docs/Glossary/REST) y el servidor del [Protocolo de Contexto de Modelo](https://modelcontextprotocol.io):

1. **Comprobación de alcance**: el token de acceso debe incluir el `object:action` alcance requerido.
2. **Política a nivel de recurso**: el usuario actual debe estar autorizado para el recurso específico a través de permisos de miembro explícitos o la política basada en roles.

Los alcances representan la *máxima* capacidad de un token. Las comprobaciones a nivel de recurso imponen el *efectivo* permiso para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización que posee el recurso |
| `organization_admin` | Un administrador de la organización que posee el recurso |
| `public_account` | El recurso pertenece a una cuenta pública |

### Permisiones de miembro

Las membresías de organización no administrativas pueden incluir alcances de permisos explícitos. Los nuevos miembros comienzan con acceso de lectura a la cuenta, organización, proyectos, voz, glosario, discusiones, tickets, actividad de traducción y análisis, además de acceso a sus propias conversaciones privadas de Toki. Un administrador de organización puede reemplazar esos alcances a través de [Miembros → Permisos](/docs/how-to/member-permissions). Una acción solicitada debe estar incluida en los alcances permitidos del miembro así como en los alcances del token al usar un token.

La propiedad privada de Toki se verifica antes de las sobrescrituras de alcance de miembros de organización. Ni las membresías que otorgan acceso ni los roles de administrador permiten el acceso a la conversación de otro usuario. La visibilidad del proyecto se verifica por separado. Consulte la [API móvil y de compañero](/docs/reference/apis/mobile) para los alcances y límites de los endpoints.

Los administradores de organización mantienen su rol de administrador. Las membresías existentes sin alcances explícitos continúan utilizando la política basada en roles de abajo hasta que se guarden los permisos.

### Permisos de rol

La tabla a continuación muestra reglas comunes basadas en roles para membresías sin alcances explícitos. No es la política completa: las solicitudes de colección, el acceso temporal y los administradores de la plataforma tienen reglas adicionales.

| Alcance | self | organization_member | organization_admin | public_account |
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
