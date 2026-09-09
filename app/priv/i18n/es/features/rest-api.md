%{
  title: "API REST",
  summary:
    "Una API REST priorizada para desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización de grano fino. Todo lo que puede hacer en el panel está disponible a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado con OpenAPI",
      description:
        "Una especificación completa OpenAPI 3.1 habilita la documentación interactiva a través de Scalar. Explore endpoints, pruebe solicitudes y genere código de cliente desde un solo archivo de especificación.",
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
        "Cada punto final de lista admite paginación basada en páginas, filtrado de campos y ordenación de inmediato. Los metadatos de respuesta predecibles facilitan la creación de clientes.",
      icon: "code"
    }
  ]
}
---
## Primero el desarrollador

La REST API es la columna vertebral de Glossia. El dashboard, la CLI y la [servidor MCP](/features/mcp-server) todos consumen los mismos endpoints. Cuando añadimos una funcionalidad, esta aterriza primero en la API y se expone en todas partes desde allí.

Esto significa que nunca estarás limitado por la UI. Cualquier flujo de trabajo que puedas imaginar, desde las integraciones CI/CD hasta los dashboards personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia usa OAuth 2.1 con PKCE para toda la autenticación de API. El flujo admite tanto clientes de primera parte como de terceros. Vea la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran programáticamente en `/oauth/register` -- con sus URIs de redirección y tipos de autorización. No hay paso de aprobación manual, ni portal por el que haya que navegar.

**Código de autorización con PKCE** -- Los usuarios autorizan a los clientes mediante una pantalla de consentimiento basada en el navegador. La extensión PKCE asegura que los tokens permanezcan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida del token** -- Los tokens de acceso se pueden intercambiar, introspeccionar y revocar a través de los puntos finales estándar de OAuth. La limitación de tasa en los puntos finales de token protege contra ataques de fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. Los [documentos de autenticación](/docs/reference/apis/authentication) abordan los ámbitos, roles y la matriz completa de permisos en detalle.

**Ámbitos** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no modificarlas. Los ámbitos siguen el `resource:action` patrón: `account:read`, `organization:write`, `glossary:admin` para administración de terminología, y así sucesivamente.

**Políticas** Verifique la relación entre el usuario y el recurso específico. Un token válido con el alcance adecuado aún no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se verifica contra ambas capas.

## Paginación, filtrado y ordenación

Todos los endpoints de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, y `has_previous_page?` para que los clientes puedan crear controles de paginación sin adivinar.

Filtrar por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordenar ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma para cada recurso.

## OpenAPI y documentación interactiva

La especificación completa OpenAPI 3.1 está disponible en `/api/openapi.json`. El [referencia de API interactiva](/docs/reference/apis/rest) está impulsada por Scalar y te permite explorar puntos finales, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier idioma pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que tus integraciones no se rompen cuando lanzamos nuevas funcionalidades.