%{
  title: "Autorización",
  summary:
    "Alcances de permisos, roles de organización y comprobaciones de acceso a nivel de recurso.",
  category: "Referencia",
  subcategory: "APIs",
  order: 2
}
---

La autenticación establece una identidad; la autorización decide qué acciones puede realizar esa identidad. Vea [Autenticación](/docs/reference/apis/authentication) para los flujos de inicio de sesión y token.

## Alcances

Los alcances controlan qué acciones puede realizar un token. Siguen el `object:action` patrón.

| Alcance | Descripción |
|-------|-------------|
| `admin:read` | Leer datos de administración de la plataforma (administradores de la plataforma únicamente) |
| `admin:write` | Actualizar datos de administración de la plataforma (administradores de la plataforma únicamente) |
| `ops:read` | Leer datos de operaciones de la plataforma (administradores de la plataforma únicamente) |
| `user:read` | Leer información del perfil de usuario |
| `user:write` | Actualizar perfil de usuario |
| `account:read` | Listar las cuentas de organización a las que tiene acceso |
| `organization:read` | Leer detalles de la organización (y listar sus organizaciones) |
| `organization:write` | Crear o actualizar organizaciones |
| `organization:claim` | Reclamar una organización |
| `organization:delete` | Eliminar organizaciones |
| `organization:admin` | Acciones administrativas de organización |
| `members:read` | Leer miembros de la organización y invitaciones |
| `members:write` | Administrar miembros y invitaciones de la organización |
| `project:read` | Leer proyectos |
| `project:write` | Crear o actualizar proyectos |
| `project:admin` | Acciones administrativas de proyectos |
| `project:delete` | Eliminar proyectos |
| `voice:read` | Leer configuración de voz |
| `voice:write` | Crear o actualizar configuración de voz |
| `voice:admin` | Acciones administrativas de voz |
| `glossary:read` | Leer entradas de glosario |
| `glossary:write` | Crear o actualizar entradas de glosario |
| `glossary:admin` | Administrar configuraciones de glosario |
| `discussion:read` | Leer discusiones |
| `discussion:write` | Crear o actualizar discusiones |
| `discussion:admin` | Acciones administrativas de discusiones |
| `ticket:read` | Leer tickets |
| `ticket:write` | Crear o actualizar tickets |
| `ticket:admin` | Acciones administrativas de tickets |
| `llm_model:read` | Leer modelos de lenguaje de la cuenta |
| `llm_model:write` | Administrar modelos de lenguaje de la cuenta |
| `translation:read` | Leer actividad de traducción del proyecto |
| `translation:write` | Escribir datos de traducción |
| `analytics:read` | Leer analítica del sitio web del proyecto |
| `toki:read` | Leer sus propias conversaciones privadas de proyecto |
| `toki:write` | Crear conversaciones privadas y encolar las respuestas del acompañante |
| `api_credentials:read` | Leer credenciales de acceso |
| `api_credentials:write` | Administrar credenciales de acceso |

El servidor de autenticación publica los alcances disponibles para los clientes a través de sus [metadatos de descubrimiento](/docs/reference/apis/authentication#discovery-endpoints). Que un alcance esté disponible no concede acceso por sí solo.

## Modelo de autorización

Glossia impone **dos capas** para la interfaz de programación de aplicaciones [Transferencia de Representación de Estado](https://developer.mozilla.org/en-US/docs/Glossary/REST) y el servidor [Protocolo de Contexto del Modelo](https://modelcontextprotocol.io):

1. **Verificación de alcance**: el token de acceso debe incluir el `object:action` alcance.
2. **Política de nivel de recurso**: el usuario actual debe estar autorizado para el recurso específico a través de permisos de miembro explícitos o la política basada en roles.

Los alcances representan la capacidad *máxima* de un token. Las comprobaciones de nivel de recurso imponen el *efectivo* permiso para un recurso específico.

### Roles

| Rol | Descripción |
|------|-------------|
| `self` | El usuario que accede a sus propios recursos |
| `organization_member` | Un miembro de la organización que posee el recurso |
| `organization_admin` | Un administrador de la organización que posee el recurso |
| `public_account` | El recurso pertenece a una cuenta pública |

### Permisos de miembro

Los miembros no administradores de la organización pueden llevar alcances de permiso explícitos. Los nuevos miembros comienzan con acceso en lectura a la cuenta, organización, proyectos, voz, glosario, discusiones, tickets, actividad de traducción, y analítica, además de acceso a sus propias conversaciones privadas Toki. Un administrador de organización puede reemplazar esos alcances a través de [Miembros → Permisos](/docs/how-to/member-permissions). Una acción solicitada debe estar incluida en los alcances permitidos del miembro así como en los alcances del token al usar un token.

La propiedad Toki privada se comprueba antes de las sobreescripciones de alcance de miembro de organización. Ninguna membresía otorga ni los roles de administrador permiten acceso a la conversación de otro usuario. La visibilidad del proyecto se comprueba por separado. Consulte la [API móvil y de acompañante](/docs/reference/apis/mobile) para los alcances de endpoints y límites.

Los administradores de la organización conservan su rol de administrador. Las membresías existentes sin alcances explícitos continúan utilizando la política basada en roles a continuación hasta que se guarden los permisos.

### Permisos de rol

La tabla a continuación muestra las reglas comunes basadas en roles para membresías sin alcances explícitos. No es la política completa: las solicitudes de colección, el acceso temporal y los administradores de la plataforma tienen reglas adicionales.

| Alcance | propio | miembro de organización | administrador de organización | cuenta pública |
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
