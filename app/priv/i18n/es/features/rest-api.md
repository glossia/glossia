%{
  title: "API REST",
  summary:
    "Una API REST centrada en desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedes hacer en el panel de control también puedes hacerlo a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Empezar ahora",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado con OpenAPI",
      description:
        "Una especificación OpenAPI 3.1 completa impulsa la documentación interactiva a través de Scalar. Explora los endpoints, prueba solicitudes y genera código de cliente desde un único archivo de especificación.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 con PKCE",
      description:
        "Registro dinámico de clientes, flujo de autorización con código y PKCE, introspección de tokens y revocación. Los clientes de terceros se autentican de forma segura sin compartir secretos.",
      icon: "key-round"
    },
    %{
      title: "Paginación y filtrado",
      description:
        "Todos los puntos finales de lista admiten paginación por página, filtrado de campos y ordenamiento incluido de serie. Los metadatos de respuesta predecibles facultan la construcción de clientes.",
      icon: "code"
    }
  ]
}
---

## Desarrollador primero

La API REST es la columna vertebral de Glossia. El panel de control, la CLI y el [MCP servidor](/features/mcp-server) consumen todos los mismos puntos finales. Cuando añadimos una funcionalidad, aterriza primero en la API y se expone desde allí en todas las demás partes.

Esto significa que nunca estás limitado por la UI. Cualquier flujo de trabajo que imagines, desde integraciones CI/CD hasta paneles de control personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia utiliza OAuth 2.1 con PKCE para toda la autenticación de API. El flujo admite tanto clientes de primera parte como de terceros. Consulta la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para la guía completa.

**Registro dinámico de clientes** -- Los clientes se registran programáticamente en `/oauth/register` con sus URIs de redirección y tipos de concesión. Sin paso de aprobación manual, sin portal que haya que navegar.

**Código de autorización con PKCE** -- Los usuarios autorizan a los clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE garantiza que los tokens permanezcan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida de los tokens** -- Los tokens de acceso pueden intercambiarse, introspectarse y revocarse a través de los puntos finales estándar de OAuth. La limitación de tasas en los puntos finales de tokens protege contra ataques de fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. La [documentación de autenticación](/docs/reference/apis/authentication) cubre alcances, roles y la matriz de permisos completa en detalle.

**Alcances** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer las configuraciones de voz, pero no puede modificarlas. Los alcances siguen el patrón `resource:action`: `account:read`, `organization:write`, `glossary:admin` para la administración de glosarios, y así sucesivamente.

**Políticas** verifican la relación entre el usuario y el recurso específico. Un token válido con el alcance adecuado aún no puede acceder a una organización de la que el usuario no sea miembro. Cada solicitud se verifica contra ambas capas.

## Paginación, filtrado y ordenación

Todos los puntos finales de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` y `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtra por cualquier campo indexado usando `filters[field]=value` como parámetros de consulta. Ordena en modo ascendente o descendente con `order_by[]` como parámetros. La interfaz es la misma en todos los recursos.

## OpenAPI y documentación interactiva

La especificación OpenAPI 3.1 completa está disponible en `/api/openapi.json`. La [referencia interactiva de la API](/docs/reference/apis/rest) está impulsada por Scalar y te permite explorar puntos finales, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de clientes en cualquier idioma pueden generarse a partir de la especificación. El contrato se versiona y es estable, por lo que tus integraciones no se rompen cuando publicamos nuevas funcionalidades.
