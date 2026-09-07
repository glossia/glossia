%{
  title: "REST API",
  summary:
    "Una REST API centrada en desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedas hacer en el panel de control, puedes hacerlo a través de la API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado con OpenAPI",
      description:
        "Una especificación completa de OpenAPI 3.1 alimenta la documentación interactiva a través de Scalar. Explora endpoints, realiza peticiones y genera código de cliente desde un único archivo de especificación.",
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
        "Cada endpoint de lista admite paginación por página,filtrado de campos y ordenación por defecto. Los metadatos de respuesta predecibles facilitan la construcción de clientes.",
      icon: "Código"
    }
  ]
}
---
## Primero el desarrollador

La API REST es la columna vertebral de Glossia. El panel, la CLI y el [servidor MCP](/features/mcp-server) consumen los mismos puntos finales. Cuando añadimos una funcionalidad, llega primero a la API y se expone desde allí en todas partes.

Esto significa que nunca te verás limitado por la interfaz de usuario. Cualquier flujo de trabajo que puedas imaginar, desde integraciones CI/CD hasta paneles personalizados, se puede construir sobre la misma interfaz estable y documentada.

## Autenticación

Glossia usa OAuth 2.1 con PKCE para toda la autenticación de la API. El flujo admite tanto clientes de primera parte como de tercera parte. Consulta la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran de forma programática en `/oauth/register` con sus URIs de redirección y tipos de concesión. Sin paso de aprobación manual ni portal para hacer clic.

**Código de autorización con PKCE** -- Los usuarios autorizan a los clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE asegura que los tokens permanezcan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida del token** -- Los tokens de acceso pueden intercambiarse, introspectarse y revocarse a través de los puntos finales estándar de OAuth. La limitación de tasa en los puntos finales de tokens protege contra ataques de fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. Los [documentos de autenticación](/docs/reference/apis/authentication) cubren alcances, roles y la matriz de permisos completa en detalle.

**Alcances** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no puede modificarlas. Los alcances siguen el patrón `resource:action`: `account:read`, `organization:write`, `glossary:admin` para la administración de terminología, y así sucesivamente.

**Políticas** verifican la relación entre el usuario y el recurso específico. Un token válido con el alcance correcto aún no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se comprueba contra ambas capas.

## Paginación, filtrado y ordenamiento

Todos los puntos finales de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` y `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtra por cualquier campo indexado usando parámetros de consulta `filters[field]=value`. Ordena ascendente o descendente con parámetros `order_by[]`. La interfaz es la misma en cada recurso.

## OpenAPI y documentación interactiva

La especificación completa OpenAPI 3.1 está disponible en `/api/openapi.json`. La [referencia de API interactiva](/docs/reference/apis/rest) está impulsada por Scalar y te permite explorar puntos finales, examinar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier idioma pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que tus integraciones no se rompen cuando lanzamos nuevas funcionalidades.