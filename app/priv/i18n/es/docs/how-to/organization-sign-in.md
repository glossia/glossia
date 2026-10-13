%{
  title: "Configurar el inicio de sesión de la organización",
  summary:
    "Conectar Google Workspace o Okta, verificar tu dominio y gestionar los permisos de los miembros.",
  category: "Guías",
  section: "platform",
  order: 8
}
---

## Conecta tu proveedor de identidad

Los administradores de la organización pueden conectar un proveedor de identidad laboral en **Configuración → Autenticación**.

1. Elige **Google Workspace** o **Okta** e introduce el dominio de correo electrónico laboral del equipo.
2. Para Okta, crea una aplicación web utilizando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Introduce su emisor, identificador de cliente y secreto de cliente. Glossia admite emisores estándar de organización Okta y el servidor de autorización `/oauth2/default`. Los secretos están encriptados en reposo. Dejar el secreto en blanco al editar mantiene el valor guardado.
3. Para Okta, registra la dirección de redirección mostrada en Glossia con tu proveedor de identidad. Para Google Workspace, Glossia gestiona la conexión de Google; no necesitas crear una aplicación de Google ni registrar una dirección de devolución de llamada.
4. Guarda la configuración. Añade el registro DNS TXT mostrado a través de tu proveedor de dominio y luego selecciona **Verificar dominio**. Cambiar el dominio de correo electrónico crea un nuevo token de verificación y deshabilita el inicio de sesión de la organización hasta que se verifique nuevamente.
5. Los miembros del equipo introducen su correo electrónico laboral en la página de inicio de sesión y seleccionan **Continuar con tu organización**. Los miembros de Google Workspace también pueden usar **Iniciar sesión con Google**.

## Configurar Google Workspace

Glossia gestiona las credenciales de la aplicación de Google. No necesitas crear una aplicación OAuth en Google Cloud, añadir una aplicación SAML personalizada en Google Admin, ni registrar una dirección de redirección. Para un dominio de Google Workspace existente, la configuración tiene lugar en Glossia y en tu proveedor DNS:

1. En **Configuración → Autenticación**, elige **Google Workspace**, introduce tu dominio de correo electrónico laboral y selecciona **Guardar configuración de autenticación**.
2. Abre la configuración DNS de tu dominio en el proveedor que aloja tu DNS, no necesariamente Google Workspace. Añade el registro mostrado en **Verificar propiedad del dominio**:

   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nombre / Host | El **Nombre del registro** mostrado en Glossia, tal como `_glossia-verification.example.com` |
   | Valor / Contenido | El **Valor del registro** mostrado en Glossia, que comienza con `glossia-domain-verification=` |

   Algunos proveedores DNS añaden tu dominio automáticamente. En ese caso, introduce solo `_glossia-verification` como el host para que el dominio no se incluya dos veces. Mantén el registro en su lugar después de la verificación.
3. Vuelve a Glossia y selecciona **Verificar dominio**. Si la verificación falla, revisa el nombre y el valor y permite tiempo para la propagación de los cambios DNS antes de intentarlo nuevamente.
4. Pide a un miembro del equipo que introduzca su correo electrónico laboral en la página de inicio de sesión y selecciona **Continuar con tu organización**, o usa **Iniciar sesión con Google**.

Glossia comprueba el correo electrónico verificado de Google y la [reclamación de dominio alojado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); una cuenta de Google personal con el mismo sufijo de correo electrónico no califica.

### Si Google bloquea el inicio de sesión

Normalmente no se requiere ninguna configuración de Google. Si tu organización restringe el acceso a aplicaciones de terceros, un administrador de Google Workspace podría necesitar aprobar Glossia:

1. Inicia sesión en la [consola de administración de Google](https://admin.google.com/) con una cuenta de administrador.
2. Dirígete a **Seguridad → Control de acceso y datos → Controles de API → Administrar acceso a aplicaciones de terceros**.
3. Busca Glossia en la lista de aplicaciones con acceso. Si no está listado, usa **Configurar nueva aplicación** para buscarla por nombre de aplicación o ID de cliente OAuth. El ID de cliente OAuth pertenece a la conexión de Google compartida de Glossia, no a una aplicación que necesites crear.
4. Revisa los permisos de inicio de sesión solicitados y permite acceso a los usuarios relevantes según las políticas de tu organización. Consulta la guía de Google [Controlar qué aplicaciones de terceros e internas acceden a los datos de Google Workspace](https://support.google.com/a/answer/7281227) para conocer los niveles de acceso y los requisitos de administrador.
5. Intenta el inicio de sesión nuevamente con una cuenta de trabajo después de que entre en vigor el cambio de política.

## Gestionar la inscripción y los permisos

Una identidad de proveedor verificada con un dominio de correo electrónico laboral coincidente se une automáticamente a la organización. Para una cuenta de Glossia existente que conecta Okta por primera vez, inicia sesión con el método existente antes de iniciar el inicio de sesión de la organización. Esto vincula el proveedor de forma segura sin permitir que un administrador de Okta tome el control de otra cuenta de Glossia. El registro público a través de otros proveedores sigue utilizando el formulario de intereses. Desactivar el proveedor detiene el inicio de sesión de la organización sin borrar las membresías existentes.

Los nuevos miembros reciben acceso básico de lectura a la cuenta, organización, proyectos, voz, glosario, discusiones y tickets. Sigue [Gestionar permisos de miembros](/docs/how-to/member-permissions) para conceder acceso adicional después de que se unan.

## Salvaguardias de acceso

La verificación de propiedad del dominio dura 30 días y se comprueba automáticamente cada día. Mantén el registro de verificación en su lugar. Si desaparece, el inicio de sesión se detiene una vez que expira la última verificación exitosa; restaura el registro y verifica nuevamente desde Configuración de autenticación. Cambiar de proveedores o desactivar el inicio de sesión de la organización elimina la verificación y quita las credenciales que pertenecen al proveedor anterior. Las reclamaciones no verificadas no reservan un dominio.

Para cuentas existentes, inicia sesión con el método existente primero, luego visita `/auth/login` e inicia el inicio de sesión de correo electrónico laboral para conectar la identidad laboral. Google también puede usar una identidad de Google ya vinculada con el mismo sujeto del proveedor. Solo coincidir con una dirección de correo electrónico nunca conecta una cuenta existente.

Eliminar un miembro bloquea la re-inscripción automática. Un administrador debe añadirla o volver a invitarla explícitamente para restaurar el acceso, incluso si su identidad laboral sigue activa.

La gestión de invitaciones de miembros, las credenciales de acceso, la edición de modelos de lenguaje y la eliminación de la organización permanecen como responsabilidades del administrador. Estos permisos no pueden delegarse mediante las casillas de verificación del alcance del miembro. La configuración de autenticación, la verificación del dominio y los cambios de alcance emiten eventos de auditoría.
