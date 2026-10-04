%{
  title: "Autorización",
  summary:
    "Alcances de permisos, roles de organización y comprobaciones de acceso a nivel de recurso.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---
La autenticación establece una identidad; la autorización decide qué acciones puede realizar esa identidad. Ver [Autenticación](/docs/reference/apis/authentication) para el inicio de sesión y flujos de tokens.

## Alcances

Los alcances controlan qué acciones puede realizar un token. Siguen el `object:action` patrón.

| Alcance | Descripción |
|-------|-------------|
| `admin:read` | Leer datos de administración de la plataforma (solo administradores de la plataforma) |
| `admin:write` | Actualizar datos de administración de la plataforma (solo administradores de la plataforma) |
| `ops:read` | Leer datos de operaciones de la plataforma (solo administradores de la plataforma) |
| `user:read` | Leer información del perfil de usuario |
| `user:write` | Actualizar perfil de usuario |
| `account:read` | Listar cuentas de organización a las que tienes acceso |
| `organization:read` | Leer detalles de la organización (y listar tus organizaciones) |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:claim` | Reclamar una organización |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Acciones administrativas de organización |
| `members:read` | Ver miembros de organización y invitaciones |
| `members:write` | Gestionar miembros de la organización y invitaciones |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Acciones administrativas de proyectos |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer configuración de voz |
| `voice:write` | Crear o actualizar configuración de voz |
| `voice:admin` | Acciones administrativas de voz |
| `glossary:read` | Leer entradas de glosario |
| `glossary:write` | Crear o actualizar entradas de glosario |
| `glossary:admin` | Gestionar configuración del glosario |
| `discussion:read` | Leer discusiones |
| `discussion:write` | Crear o actualizar discusiones |
| `discussion:admin` | Acciones de discusiones administrativas |
| `ticket:read` | Leer tickets |
| `ticket:write` | Crear o actualizar tickets |
| `ticket:admin` | Acciones administrativas de ticket |
| `llm_model:read` | Leer modelos de idioma de la cuenta |
| `llm_model:write` | Gestionar modelos de idioma de la cuenta |
| `translation:write` | Escribir datos de traducción |
| `api_credentials:read` | Credenciales de acceso de lectura |
| `api_credentials:write` | Gestionar credenciales de acceso |

del servidor de autenticación [metadatos de descubrimiento](/docs/reference/apis/authentication#discovery-endpoints) publica los ámbitos disponibles para los clientes. Que un ámbito esté disponible no otorga acceso por sí solo.

## Modelo de autorización

Glossia impone **dos capas** para la [Transferencia de Estado Representacional](https://developer.mozilla.org/en-US/docs/Glossary/REST) interfaz de programación de aplicaciones y la [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io) servidor:

1. **Verificación de alcance**: el token de acceso debe incluir el requerido `object:action` alcance.
2. **Política a nivel de recurso**: el usuario actual debe estar autorizado para el recurso específico a través de permisos de miembro explícitos o la política basada en roles.

Los alcances representan el *máximo* capacidad de un token. Las verificaciones a nivel de recurso imponen el *real* permiso para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización que posee el recurso |
| `organization_admin` | Un administrador de la organización que posee el recurso |
| `public_account` | El recurso pertenece a una cuenta pública |

### Permisos de miembros

Las membresías de organización de los no administradores pueden tener alcances de permiso explícitos. Los nuevos miembros comienzan con acceso de lectura a la cuenta, organización, proyectos, voz, glosario, discusiones y tickets. Un administrador de la organización puede reemplazar esos alcances a través de [Miembros → Permisos](/docs/how-to/member-permissions). Una acción solicitada debe estar incluida en los alcances permitidos del miembro y en los alcances del token al utilizar un token.

Los administradores de la organización mantienen su rol de administrador. Las membresías existentes sin alcance explícito continúan utilizando la política basada en roles a continuación hasta que los permisos se guarden.

### Permisos de rol

La siguiente tabla muestra las reglas comunes basadas en roles para las membresías sin alcance explícito. No es la política completa: las solicitudes de recopilación, el acceso temporal y los administradores de plataforma tienen reglas adicionales.

| Alcance | self | organization\_member | organization\_admin | public\_account |
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