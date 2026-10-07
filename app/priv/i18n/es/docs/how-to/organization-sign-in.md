%{
  title: "Configurar inicio de sesión de la organización",
  summary:
    "Conectar Google Workspace u Okta, verificar el dominio y gestionar los permisos de los miembros.",
  category: "Guía",
  section: "platform",
  order: 8
}
---
## Conecta tu proveedor de identidad

Los administradores de la organización pueden conectar un proveedor de identidad corporativo en **Configuración → Autenticación**.

1. Elige **Google Workspace** o **Okta** y introduce el dominio de correo electrónico del equipo.
2. Para Okta, crea una aplicación web utilizando [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Introduce su emisor, identificador de cliente y secreto del cliente. Glossia soporta emisores estándar de organización de Okta y el `/oauth2/default` servidor de autorización. Los secretos están encriptados en reposo. Dejar el secreto en blanco al editar mantiene el valor guardado.
3. Para Okta, registra la dirección de redirección mostrada en Glossia con tu proveedor de identidad. Para Google Workspace, Glossia gestiona la conexión de Google; no es necesario crear una aplicación de Google ni registrar una dirección de devolución de llamada.
4. Guarda la configuración. Añade el registro DNS TXT mostrado a través de tu proveedor de dominio, y luego selecciona **Verificar dominio**. Cambiar el dominio de correo electrónico crea un nuevo token de verificación y deshabilita el inicio de sesión de la organización hasta verificarlo de nuevo.
5. Los miembros del equipo ingresan su correo electrónico de trabajo en la página de inicio de sesión y seleccionan **Continuar con tu organización**. Los miembros de Google Workspace también pueden usar **Iniciar sesión con Google**.

## . Configurar Google Workspace

Glossia gestiona las credenciales de la aplicación de Google. No necesitas crear una aplicación OAuth en Google Cloud, añadir una aplicación SAML personalizada en Google Admin, ni registrar una dirección de redirección. Para un dominio Google Workspace existente, la configuración se realiza en Glossia y en tu proveedor de DNS:.

1. En **Ajustes → Autenticación**, elige **Google Workspace**, ingresa el dominio de tu correo electrónico laboral y selecciona **Guardar configuración de autenticación**.

2. Abre la configuración DNS de tu dominio en el proveedor que aloja tu DNS, que no necesariamente es Google Workspace. Añade el registro mostrado en **Verificar propiedad del dominio**:
   
   | Campo | Valor |
   | --- | --- |
   | Tipo | `TXT` |
   | Nombre / Host | El **nombre del registro** mostrado en Glossia, tal como `_glossia-verification.example.com` |
   | Valor / Contenido | El **valor del registro** mostrado en Glossia, comenzando con `glossia-domain-verification=` |
   
   Algunos proveedores DNS agregan su dominio automáticamente. En ese caso, ingrese solo `_glossia-verification` en el host para que el dominio no se incluya dos veces. Mantenga el registro en su lugar después de la verificación.

3. Volver a Glossia y seleccionar **Verificar dominio**. Si la verificación falla, verifica el nombre y el valor y espere a que los cambios de DNS se propaguen antes de intentar de nuevo.

4. Pídele a un miembro del equipo que introduzca su correo electrónico de trabajo en la página de inicio de sesión y seleccione **Continuar con su organización**, o utilice **Iniciar sesión con Google**.

Glossia comprueba el correo electrónico verificado de Google y [la afirmación de dominio alojado](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); una cuenta personal de Google con el mismo sufijo de correo electrónico no califica.

### Si Google bloquea el inicio de sesión

Normalmente no se requiere ninguna configuración de Google. Si su organización restringe el acceso de aplicaciones de terceros, un administrador de Google Workspace puede necesitar aprobar Glossia:

1. Inicie sesión en [Consola de administración de Google](https://admin.google.com/) con una cuenta de administrador.
2. Ir a **Seguridad → Control de acceso y datos → Controles de API → Administrar el acceso a aplicaciones de terceros**.
3. Encuentra Glossia en la lista de aplicaciones a las que tienes acceso. Si no aparece, usa **Configurar nueva aplicación** para buscarla por nombre de aplicación o ID de cliente OAuth. El ID de cliente OAuth pertenece a la conexión compartida de Google de Glossia, no a una aplicación que debas crear.
4. Revisa los permisos de inicio de sesión solicitados y permite el acceso a los usuarios relevantes según la política de tu organización. Consulta las directrices de Google sobre [Administrar qué aplicaciones de terceros e internas acceden a los datos de Google Workspace](https://support.google.com/a/answer/7281227) Guía para niveles de acceso y requisitos de administrador.
5. Vuelva a intentar iniciar sesión con una cuenta de trabajo una vez que el cambio de política surta efecto.

## Gestionar inscripciones y permisos

Una identidad de proveedor verificada con un dominio exacto de correo de trabajo se une automáticamente a la organización. Para una cuenta existente de Glossia que conecta Okta por primera vez, inicie sesión con el método existente antes de comenzar el inicio de sesión en la organización. Esto vincula de forma segura el proveedor sin permitir que un administrador de Okta controle otra cuenta de Glossia. El registro público a través de otros proveedores continúa utilizando el formulario de interés. Desactivar el proveedor detiene el inicio de sesión en la organización sin eliminar los miembros existentes.

Los nuevos miembros reciben acceso de lectura básico a la cuenta, organización, proyectos, voz, glosario, discusiones y tickets. Siga [Gestionar permisos de miembros](/docs/how-to/member-permissions) para conceder acceso adicional después de que se unan.

## Salvaguardias de acceso

La verificación de propiedad del dominio dura 30 días y se comprueba automáticamente cada día. Mantenga el registro de verificación vigente. Si desaparece, el inicio de sesión se detiene una vez que la última verificación exitosa vence; restablezca el registro y verifique nuevamente desde la configuración de autenticación. Cambiar proveedores o desactivar el inicio de sesión en la organización limpia la verificación y elimina las credenciales del proveedor anterior. Las afirmaciones no verificadas no reservan un dominio.

Para las cuentas existentes, inicie sesión con el método existente primero, luego visite `/auth/login` y comience el inicio de sesión con correo de trabajo para conectar la identidad de trabajo. Google también puede utilizar una identidad de Google ya vinculada con el mismo sujeto del proveedor. Coincidir solo con una dirección de correo electrónico nunca conecta una cuenta existente.

Eliminar a un miembro bloquea la reinscripción automática. Un administrador debe agregarlos o invitarlos explícitamente nuevamente para restaurar el acceso, incluso si su identidad de trabajo sigue activa.

La gestión de invitaciones de miembros, las credenciales de acceso, la edición de modelos de lenguaje y la eliminación de la organización siguen siendo responsabilidades de administrador. Estos permisos no pueden delegarse a través de las casillas de verificación del alcance del miembro. La configuración de autenticación, la verificación de dominio y los cambios de alcance emiten eventos de auditoría.