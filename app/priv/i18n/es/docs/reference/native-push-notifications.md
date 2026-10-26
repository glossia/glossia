%{
  title: "Notificaciones push nativas",
  summary:
    "Configuración del proveedor, registro de dispositivos con consentimiento, política de entrega y cargas nativas.",
  category: "referencia",
  section: "platform",
  order: 30
}
---

## Transporte y credenciales

Glossia envía directamente a APNs para iOS y FCM HTTP v1 para Android. PostgreSQL almacena los registros; Oban cola la entrega. No se necesita ningún servicio de mensajería ni Firebase iOS SDK. La aceptación del proveedor no es un acuse de recibo de entrega ni de lectura. Las fallas de red ambiguas pueden producir alertas duplicadas.

Los secretos del proveedor pertenecen solo al sistema de gestión de secretos existente del servidor. Nunca ponga claves privadas de APNs ni JSON de cuentas de servicio de Firebase en construcciones móviles, archivos de repositorio, registros o configuraciones visibles para el cliente. Los identificadores de aplicaciones públicas de Android de Firebase no son credenciales de cuenta de servicio.

| Variable de entorno | Significado |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | ID de equipo de Apple de diez caracteres. |
| `GLOSSIA_APNS_KEY_ID` | ID de clave de firma de Apple de diez caracteres. |
| `GLOSSIA_APNS_PRIVATE_KEY` | Clave privada P-256 firmada codificada en PEM, conservando los saltos de línea. |
| `GLOSSIA_APNS_TOPIC` | El identificador de paquete exacto de la aplicación iOS firmada. Los clientes no pueden elegirlo. |
| `GLOSSIA_APNS_ENVIRONMENT` | `production` (default), `sandbox`, o explícitamente `both` para una clave que soporta ambos. |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | JSON de cuenta de servicio de Firebase Android con `type`, `project_id`, `client_email` y la clave privada RSA `private_key`. |

Las credenciales de APNs ausentes deshabilitan solo iOS. Las credenciales de FCM ausentes deshabilitan solo Android. Los proveedores configurados parciales o malformados fallan en la parseo de configuración con un error sin secreto. El entorno de APNs se controla en el registro y la entrega; obténlo del perfil de provisión firmado, no de las suposiciones del modo de compilación. APNs usa un repositorio Finch exclusivo HTTP/2-only y autenticación ES256. FCM intercambia una servicial de cuenta RS256 en el fijo endpoint OAuth de Google, luego usa su fijo endpoint HTTP v1. Las redirecciones y los reintentos del cliente HTTP están deshabilitados.

## API de Registro

Todas las rutas requieren un token de acceso bearer OAuth emitido al cliente PKCE público dinámicamente registrado por instalación de la aplicación nativa. Su única URI de redirección debe ser `glossia://oauth/callback`; refrescar y revocar deben ser públicos, sin métodos de autenticación de secreto de cliente. El cliente Expo compartido heredado, los tokens de cuenta, las sesiones web y otros clientes OAuth no son identidades de instalación y no pueden registrar dispositivos. Esto verifica la forma del cliente, no la atestación de dispositivos.

`PUT /api/me/push-devices/:installation_id` acepta exactamente:

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: UUID generado por el cliente. También es el `registration_id` devuelto y entregado.
- `platform`: `ios` o `android`.
- `environment`: `sandbox` o `production` para iOS; solo `production` para Android.
- Tokens de iOS: 32–512 caracteres hexadecimales, longitud par, normalizados a minúsculas.
- Tokens de Android: 16–4096 caracteres ASCII imprimibles no espacio.
- Solicitud PUT exitosa: `{"registered":true,"registration_id":"<installation UUID>"}`.
- Campos desconocidos, incluyendo selectores de propietario, tema, host y URLs de proveedor, son rechazados.

`DELETE /api/me/push-devices/:installation_id` devuelve `{"deleted":true}` idempóticamente. IDs desconocidos se convierten en tombstones, por lo que un PUT tardío no puede revivir una instalación después de la desconexión. Una instalación desconexada diferente de un usuario nunca cambia. El mismo cliente OAuth nativo podría dimitir la instalación de su usuario anterior durante la recuperación de desconexión sin línea, pero la propiedad nunca se mueve. Rotar a un UUID de instalación nuevo después de `409 installation_retired`.

`GET /api/me/push-devices/capabilities` devuelve `{"ios":true,"android":false}` según proveedores configurados; tiene el mismo requisito de autenticación. Una capacidad iOS verdadera no anula las restricciones de entorno de APNs.

Las respuestas son `no-store`. Las mutaciones tienen un límite de 120 peticiones por usuario por hora, además del límite de API. Autenticación bearer ausente/inválida devuelve 401; credenciales no nativas devuelven 403; datos de dispositivo inválidos devuelven 400; instalaciones retiradas/conflictivas devuelven 409; proveedores no disponibles devuelven 503. La limpieza sigue disponible cuando un proveedor está deshabilitado.

## Intenciones de entrega

Los llamantes internos usan la API fija después de que su transacción de origen se confirma:

```elixir
Glossia.Push.notify_user(user_id, "toki_completed", %{
  conversation_id: conversation.id,
  message_id: completed_user_message.id
})

Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
  translation_session_id: session.id,
  review_id: review.id
})
```

El tipo también puede ser el átomo correspondiente. El retorno es `{:ok, queued_count}` o `{:error, :invalid_notification}`. No hay API de envío público para destinatario arbitrario, texto personalizado de notificación, reintento de inferencia o suscripción implícita.

`toki_completed` requiere el mensaje exacto de **usuario** completado y su respuesta completada de asistente. En conversaciones privadas el destinatario debe poseer el historial; en conversaciones de objetivo compartido deben seguir siendo un participante fluido invitado elegible y el objetivo debe estar abierto. Comprobó acceso actual a Toki/proyecto y, para conversaciones vinculadas a fuentes, acceso actual de lectura de traducción y existencia de fuente. Un mensaje completado diferente o un ID de mensaje de asistente no es sustituto.

`linguistic_input_needed` requiere el objetivo abierto identificado en la sesión de traducción especificada y un participante fluido invitado elegible. Una fuente solo de sesión queda aceptada para compatibilidad y resuelve un objetivo abierto elegible. Las revisiones en otra sesión no califican. Todos los compañeros elegidos autorizados se unen a la misma conversación低点同; la entrega verifica independientemente la fluencia actual, acceso a Toki/traduccion/proyecto y membresía.

Hay a lo sumo diez registros activos por usuario. Los tokens se cifran con el cofre Cloak existente y se indexan por un resumen SHA-256. El movimiento de token retira el registro antiguo, y la invalidación del proveedor compara el resumen/entorno intento antes de borrar nada. Las marcas de tiempo de última invalidación de APNs no retiran los registros actualizados después de esa marca de tiempo.

Los trabajos de entrega contienen solo IDs, tipo, IDs de fuente y caducidad. Cada intento vuelve a verificar el registro, propietario, concesión actual persistente de renovación de OAuth nativa y alcances, fuente, membresía y caducidad. Lo verifica nuevamente después de la adquisición de credenciales del proveedor, inmediatamente antes del transporte. La caducidad del token de acceso por sí sola no termina una sesión de renovación aún válida. La revocación, caducidad de renovación, falta de acceso a la fuente, desconexión o revisiones resueltas cancelan la entrega.

Ambos tipos caducan tras una hora. Hay como máximo cinco intentos del proveedor, incluidas las pausas de presión del proveedor. "Retry-After" se respeta solo dentro del tiempo de vida de la notificación. No se devuelve un cuerpo de respuesta o token del proveedor como un error de trabajo. Refresque los registros en primer plano; los registros no refrescados durante 60 días son retirados. El trabajador de poda horaria escanea un lote rotatorio acotado de 1,000 filas y elimina tokens para sesiones obsoletas o terminadas. Los monumentos funerarios retienen solo las IDs de instalación/cliente, plataforma/entorno y marcas de tiempo del ciclo de vida indefinidamente para bloquear solicitudes retardadas; las filas retiradas no tienen usuario, token o resumen. La eliminación de cuentas corta la referencia del usuario, previene toda la entrega inmediatamente y el trabajador de poda borra el token retenido.

Las credenciales del proveedor usan un caché Cachex acotado y sensible a la caducidad. La rotación de clave cambia la identidad de caché. Los JWT de APNs se reutilizan durante 50 minutos; las credenciales de FCM caducan cinco minutos antes de la expiración del proveedor (a lo sumo 50 minutos). Los fallos no se guardan en caché.

## Versión de la carga 1

APNs incluye la alerta genérica **Glossia / Tienes una actualización en Glossia.** FCM envía mensajes de solo datos con el mismo `title` y `body` para renderizado local. Ninguno incluye prompts privados, respuestas, preguntas, fragmentos de fuente o títulos de proyecto. Los campos de rutas son cadenas de texto:

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

Ambos tipos de notificación abren `/org/project/toki/CONVERSATION_UUID`; las solicitudes de ayuda lingüística abren su hilo de objetivo compartido. El `server` es el origen HTTPS del punto final Phoenix configurado, nunca encabezados de solicitud o input del cliente. Las configuraciones de puntos finales HTTP solo fallan en cierre en la entrega. Los clientes nativos deben rechazar versiones desconocidas, orígenes/registros desajustados y rutas no reconocidas; el toque nunca cambia servidores o ejecuta mutaciones. El destino obtenido debe seguir pasando la autenticación de API normal.

## Integración de tiempo de ejecución

La aplicación padre inicia `Glossia.Push.Supervisor` antes de Oban, proporcionando el caché de credenciales y el pool dedicado de APNs Finch. La configuración de tiempo de ejecución llama a `Glossia.Push.Config.parse!(System.get_env())`. La cola `push` de Oban tiene concurrencia cinco y ejecuta `Glossia.Push.Prune` a la hora. Las tres rutas de registro se ejecutan en el pipeline existente de autenticación de portador de API.

El registro de solicitudes redacta los tokens de dispositivo. El punto final extiende el depurador de cuerpo por defecto de Sentry con el filtro de parámetros de Phoenix, preservando sus protecciones existentes:

```elixir
config :phoenix, :filter_parameters, ["password", "passwd", "secret", "token"]

# Endpoint request-body scrubber
plug Sentry.PlugContext, body_scrubber: {__MODULE__, :scrub_request_body}
def scrub_request_body(conn) do
  conn
  |> Sentry.PlugContext.default_body_scrubber()
  |> Phoenix.Logger.filter_values()
end

# Defense in depth: no Phoenix parameter logging for enrollment
put "/me/push-devices/:installation_id", PushDeviceController, :update, log: false
```

No conserve los cuerpos crudos de las solicitudes de push en la telemetría personalizada o informes de excepción.

Solo los procesos padre web/trabajador necesitan al supervisor de push y la cola. Los pods ejecutores de traducción pueden poner en cola IDs sin credenciales, un pool de APNs o un nuevo servicio de mensajería. Aplique la migración a través del flujo de lanzamiento habitual. Mantenga los datos de cuenta exportados libres de tokens del proveedor. No elimine los monumentos funerarios como limpieza habitual de retención.

Las verificaciones de dispositivo físico siguen siendo necesarias: compilaciones configuradas firmadas de iOS/Android, permisos permitidos/denegados, entrega en primer plano/fondo/terminada, toques de inicio en frío, rotación de tokens del proveedor, credenciales caducadas, limpieza de desconexión sin línea y cambio de cuenta. Las pruebas de proveedor simuladas no establecen la entrega en vivo. Las compilaciones nativas incluyen el soporte del ciclo de vida de notificaciones y las dependencias de Firebase de Android, pero este código no provisiona credenciales, infraestructura compartida, perfiles de configuración firmados o identificadores de aplicaciones de Firebase.
