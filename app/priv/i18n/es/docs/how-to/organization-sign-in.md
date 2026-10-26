%{
  title: "Configurar el inicio de sesión de la organización",
  summary:
    "Conecta Google Workspace o Okta, verifica tu dominio y gestiona los permisos de los miembros.",
  category: "Tutorial",
  section: "platform",
  order: 8
}
---

## Conectar tu proveedor de identidad

Los administradores de la organización pueden conectar un proveedor de identidad laboral en **Configuración → Autenticación**.

1. Elige **Google Workspace** o **Okta** e introduce el dominio de correo electrónico laboral del equipo.
2. Para Okta, crea una aplicación web utilizando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Introduce su emisor, identificador de cliente y secreto de cliente. Glossia admite emisores de organización estándar de Okta y el `/oauth2/default` servidor de autorización. Los secretos están cifrados en reposo. Dejar el secreto en blanco al editar preserva el valor guardado.
3. Para Okta, registra la dirección de redirección mostrada en Glossia con tu proveedor de identidad. Para Google Workspace, Glossia gestiona la conexión con Google; no necesitas crear una aplicación de Google ni registrar una dirección de retorno de llamada.
4. Guarda la configuración. Añade el registro DNS TXT mostrado a través de tu proveedor de dominio, luego selecciona **Verificar dominio**. Cambiar el dominio de correo electrónico crea un nuevo token de verificación y desactiva el inicio de sesión en la organización hasta verificar de nuevo.
5. Los miembros del equipo introducen su correo electrónico laboral en la página de inicio de sesión y seleccionan **Continuar con tu organización**. Los miembros de Google Workspace también pueden usar **Acceder con Google**.

## Configurar Google Workspace

Glossia gestiona las credenciales de la aplicación de Google. No necesitas crear una aplicación OAuth en Google Cloud, añadir una aplicación personalizada SAML en Google Admin ni registrar una dirección de redirección. Para un dominio de Google Workspace existente, la configuración se realiza en Glossia y en tu proveedor de DNS:

1. En **Configuración → Autenticación**, elige **Google Workspace**, introduce tu dominio de correo electrónico laboral y selecciona **Guardar configuración de autenticación**.
2. Abre la configuración DNS de tu dominio en el proveedor que aloja tus DNS, no necesariamente Google Workspace. Añade el registro mostrado en **Verificar propiedad del dominio**:

   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nombre / Host | El **Nombre del registro** mostrado en Glossia, tal como `_glossia-verification.example.com` |
   | Valor / Contenido | El **Valor del registro** mostrado en Glossia, comenzando con `glossia-domain-verification=` |

   Algunos proveedores de DNS agregan tu dominio automáticamente. En ese caso, introduce solo `_glossia-verification` como host para que el dominio no se incluya dos veces. Mantén el registro en su lugar después de la verificación.
3. Vuelve a Glossia y selecciona **Verificar dominio**. Si la verificación falla, comprueba el nombre y el valor y permite tiempo para que los cambios de DNS se propaguen antes de intentarlo de nuevo.
4. Pide a un miembro del equipo que introduzca su correo electrónico laboral en la página de inicio de sesión y seleccione **Continuar con tu organización**, o usa **Acceder con Google**.

Glossia comprueba el correo electrónico verificado de Google y la [reclamación de dominio alojado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); una cuenta personal de Google con el mismo sufijo de correo electrónico no califica.

### Si Google bloquea el inicio de sesión

No se requiere normalmente ninguna configuración del lado de Google. Si tu organización restringe el acceso de aplicaciones de terceros, un administrador de Google Workspace puede necesitar aprobar Glossia:

1. Inicia sesión en [Consola de administración de Google](https://admin.google.com/) con una cuenta de administrador.
2. Ve a **Seguridad → Control de acceso y datos → Controles de API → Gestionar acceso a aplicaciones de terceros**.
3. Busca Glossia en la lista de aplicaciones accesadas. Si no aparece, usa **Configurar nueva aplicación** para buscarla por nombre de aplicación o ID de cliente OAuth. El ID de cliente OAuth pertenece a la conexión compartida de Google de Glossia, no a una aplicación que debas crear.
4. Revisa los permisos de inicio de sesión solicitados y permite el acceso a los usuarios relevantes según la política de tu organización. Consulta la guía de Google [Controlar qué aplicaciones de terceros y internas acceden a los datos de Google Workspace](https://support.google.com/a/answer/7281227) para conocer los niveles de acceso y los requisitos de administrador.
5. Intenta iniciar sesión nuevamente con una cuenta laboral una vez que la política entre en vigor.

## Gestionar inscripciones y permisos

Una identidad de proveedor verificada con un dominio de correo electrónico laboral que coincida exactamente se une automáticamente a la organización. Para una cuenta existente de Glossia que conecta Okta por primera vez, inicia sesión con el método existente antes de iniciar el inicio de sesión en la organización. Esto vincula el proveedor de forma segura sin permitir a un administrador de Okta usurpar otra cuenta de Glossia. El registro público a través de otros proveedores continúa utilizando el formulario de interés. Desactivar el proveedor detiene el inicio de sesión en la organización sin eliminar a los miembros existentes.

Los nuevos miembros reciben acceso básico de lectura a la cuenta, la organización, los proyectos, la voz, el glosario, las discusiones y los tickets. Sigue [Gestionar permisos de miembro](/docs/how-to/member-permissions) para otorgar acceso adicional después de que se unan.

## Protecciones de acceso

La verificación de propiedad del dominio dura 30 días y se comprueba automáticamente todos los días. Mantiene el registro de verificación en su lugar. Si desaparece, el inicio de sesión se detiene una vez que vence la última verificación exitosa; restaura el registro y verifica de nuevo desde Configuración de autenticación. Cambiar proveedores o desactivar el inicio de sesión de la organización limpia la verificación y elimina las credenciales pertenecientes al proveedor anterior. Las afirmaciones no verificadas no reservan un dominio.

Para cuentas existentes, inicia sesión primero con el método existente, luego visita `/auth/login` e inicia el inicio de sesión con el correo laboral para conectar la identidad laboral. Google también puede usar una identidad de Google ya vinculada con la misma identidad del proveedor. Coincidir solo una dirección de correo electrónico nunca conecta una cuenta existente.

Eliminar un miembro bloquea la reinscripción automática. Un administrador debe añadirles o invitarles explícitamente de nuevo para restaurar el acceso, incluso si su identidad laboral sigue activa.

La gestión de invitaciones de miembros, las credenciales de acceso, la edición de modelos de lenguaje y la eliminación de la organización siguen siendo responsabilidades de administrador. Estos permisos no pueden delegarse a través de las casillas de alcance de miembro. La configuración de autenticación, la verificación de dominio y los cambios de alcance emiten eventos de auditoría.
