%{
  title: "API REST",
  summary:
    "Una API REST centrada en desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedes hacer en el panel de control, puedes hacerlo a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado con OpenAPI",
      description:
        "Una especificación OpenAPI 3.1 completa habilita documentación interactiva a través de Scalar. Explora endpoints, prueba solicitudes y genera código del cliente desde un único archivo de especificación.",
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
        "Todos los endpoints de lista admiten paginación basada en páginas, filtrado por campo y ordenación de forma nativa. Los metadatos de respuesta predecibles facilitan la construcción de clientes.",
      icon: "code"
    }
  ]
}
---
## Desarrollador primero

La API REST es la columna vertebral de Glossia. El panel de control, la CLI y el [Servidor MCP](/features/mcp-server) todos consumen los mismos endpoints. Cuando añadimos una funcionalidad, esta llega primero a la API y se expone en los demás lugares desde ahí.

Esto significa que nunca estás limitado por la interfaz de usuario. Cualquier flujo de trabajo que puedas imaginar, desde integraciones CI/CD hasta paneles personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia usa OAuth 2.1 con PKCE para toda la autenticación de API. El flujo soporta tanto clientes de primera parte como de terceros. Ver [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran programáticamente en `/oauth/register` con sus URIs de redirección y tipos de concesión. No hay paso de aprobación manual, ni portal que deba ser visitado.

**Código de autorización con PKCE** -- Los usuarios autorizan clientes a través de una pantalla de consentimiento basada en navegador. La extensión PKCE asegura que los tokens permanezcan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida de tokens** -- Los tokens de acceso pueden intercambiarse, introspeccionarse y revocarse a través de puntos finales OAuth estándar. La limitación de tasa en los puntos finales de tokens protege contra fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. La [documentación de autenticación](/docs/reference/apis/authentication) cubre los ámbitos, roles y la matriz completa de permisos en detalle.

**Ámbitos** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no modificarlas. Los ámbitos siguen `resource:action` el patrón: `account:read`, `organization:write`, `glossary:admin` para la administración de terminología, y así sucesivamente.

**Políticas** Verificar la relación entre el usuario y el recurso específico. Un token válido con el alcance correcto aún no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se verifica en ambas capas.

## Paginación, filtrado y ordenamiento

Todos los puntos finales de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`y ya `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtrar por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordenar ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma en cada recurso.

## OpenAPI y documentación interactiva

La especificación completa de OpenAPI 3.1 está disponible en `/api/openapi.json`. El [referencia de API interactiva](/docs/reference/apis/rest) está impulsada por Scalar y le permite explorar endpuntos, revisar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier idioma pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que sus integraciones no se rompen cuando lanzamos nuevas características.