%{
  title: "API REST",
  summary:
    "Una API REST centrada en el desarrollador, con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedes hacer en el panel de control, puedes hacerlo a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentada con OpenAPI",
      description:
        "Una especificación completa de OpenAPI 3.1 habilita la documentación interactiva vía Scalar. Explora endpoints, prueba solicitudes y genera código de cliente desde un único archivo de especificación.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 con PKCE",
      description:
        "Registro dinámico de clientes, flujo de código de autorización con PKCE, introspección de tokens y revocación. Los clientes de terceros se autentican de forma segura sin compartir secretos.",
      icon: "key-round"
    },
    %{
      title: "Paginación y filtrado",
      description:
        "Cada endpoint de lista soporta paginación basada en páginas, filtrado por campo y ordenamiento de serie. Los metadatos de la respuesta predecibles hacen que los clientes sean sencillos de crear.",
      icon: "code"
    }
  ]
}
---

## Desarrollador primero

La API REST es la columna vertebral de Glossia. El dashboard, la CLI y el [servidor MCP](/features/mcp-server) consumen todos los mismos endpoints. Cuando añadimos una característica, aterriza primero en la API y se hace visible en todas partes a partir de ahí.

Esto significa que nunca estás limitado por la interfaz de usuario. Cualquier flujo de trabajo que puedas imaginar, desde integraciones CI/CD hasta paneles personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia utiliza OAuth 2.1 con PKCE para toda autenticación de API. El flujo soporta tanto clientes de primera parte como de terceros. Consulta los [documentos de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran programáticamente en `/oauth/register` con sus URIs de redirección y tipos de concesión. Sin paso manual de aprobación, sin portal que hacer clic.

**Código de autorización con PKCE** -- Los usuarios autorizan clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE asegura que los tokens permanezcan seguros incluso para clientes públicos que no pueden guardar un secreto.

**Ciclo de vida del token** -- Los tokens de acceso pueden ser intercambiados, introspectados y revocados a través de endpoints OAuth estándar. La limitación de velocidad en los endpoints de tokens protege contra fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. Los [documentos de autenticación](/docs/reference/apis/authentication) abarcan alcances, roles y la matriz completa de permisos en detalle.

**Alcances** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no puede modificarlas. Los alcances siguen el patrón `resource:action`: `account:read`, `organization:write`, `glossary:admin` para la administración del glosario, y así sucesivamente.

**Políticas** verifican la relación entre el usuario y el recurso específico. Un token válido con el alcance adecuado aún no puede acceder a una organización a la que el usuario no pertenezca. Cada solicitud es revisada contra ambas capas.

## Paginación, filtrado y ordenación

Todos los endpoints de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, y `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtra por cualquier campo indexado usando parámetros de consulta `filters[field]=value`. Ordena ascendente o descendente con parámetros `order_by[]`. La interfaz es la misma en todos los recursos.

## OpenAPI y documentación interactiva

La especificación completa OpenAPI 3.1 está disponible en `/api/openapi.json`. La [referencia interactiva de la API](/docs/reference/apis/rest) está potenciada por Scalar y te permite explorar endpoints, inspeccionar esquemas y hacer solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier idioma pueden generarse desde la especificación. El contrato está versionado y estable, por lo que tus integraciones no se rompen cuando lanzamos nuevas características.
