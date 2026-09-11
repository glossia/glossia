%{
  title: "REST API",
  summary:
    "Una REST API orientada a desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedes hacer en el panel de control, puedes hacerlo a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado en OpenAPI",
      description:
        "Una especificación OpenAPI 3.1 completa impulsa la documentación interactiva a través de Scalar. Explora los endpoints, prueba solicitudes y genera código de cliente desde un único archivo de especificación.",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 con PKCE",
      description:
        "Registro dinámico del cliente, flujo de código de autorización con PKCE, introspección de tokens y revocación. Los clientes de terceros se autentican de forma segura sin compartir secretos.",
      icon: "key-round"
    },
    %{
      title: "Paginación y filtrado",
      description:
        "Todos los puntos de acceso de listas soportan paginación por página, filtrado de campos y ordenación de forma nativa. Los metadatos de respuesta predecibles facilitan la creación de clientes.",
      icon: "code"
    }
  ]
}
---
## Desarrollador primero

La REST API es la columna vertebral de Glossia. El panel, la CLI y el [servidor MCP](/features/mcp-server) todos consumen los mismos endpoints. Cuando añadimos una funcionalidad, esta llega primero a la API y se refleja en todas las demás partes desde allí.

Esto significa que nunca estás limitado por la interfaz de usuario. Cualquier flujo de trabajo que puedas imaginar, desde integraciones de CI/CD hasta tableros personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia utiliza OAuth 2.1 con PKCE para toda la autenticación de API. El flujo admite tanto clientes de primera parte como de tercera parte. Consulta los [documentos de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro de clientes dinámico** -- Los clientes se registran programáticamente en `/oauth/register` con sus URIs de redirección y tipos de concesión. No hay paso de aprobación manual, sin portal para navegar.

**Código de autorización con PKCE** -- Los usuarios autorizan a los clientes mediante una pantalla de consentimiento basada en el navegador. La extensión PKCE garantiza que los tokens permanezcan seguros incluso para clientes públicos que no puedan almacenar un secreto.

**Ciclo de vida del token** -- Los tokens de acceso pueden intercambiarse, introspectarse y revocarse mediante puntos finales estándar de OAuth. La limitación de tasa en los puntos finales de tokens protege contra fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. La [documentación de autenticación](/docs/reference/apis/authentication) cubre los ámbitos, roles y la matriz de permisos completa en detalle.

**Ámbitos** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no modificarlas. Ámbitos siguen el `resource:action` patrón: `account:read`, `organization:write`, `glossary:admin` ,para administración de terminología, y así sucesivamente.

**Políticas** verifique la relación entre el usuario y el recurso específico. Un token válido con el alcance correcto aún no puede acceder a una organización a la que el usuario no pertenezca. Todas las solicitudes se verifican contra ambas capas.

## Paginación, filtrado y ordenación

Todos los puntos finales de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`El documento reensamblado previamente falló la validación: la recuperación de texto literal de Markdown debe devolver un array de cadenas JSON de longitud coincidente `total_pages`, `current_page`, `page_size`, `has_next_page?`, y `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtrar por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordenar ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma en cada recurso.

## OpenAPI y documentación interactiva

La especificación completa de OpenAPI 3.1 está disponible en `/api/openapi.json`. El [referencia API interactiva](/docs/reference/apis/rest) está impulsada por Scalar y le permite explorar puntos finales, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier lenguaje pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que sus integraciones no se rompen cuando lanzamos nuevas funcionalidades.