%{
  title: "API REST",
  summary:
    "Una API REST orientada al desarrollador con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedas hacer en el panel de control, puedes hacerlo a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado con OpenAPI",
      description:
        "Una especificación completa de OpenAPI 3.1 habilita la documentación interactiva a través de Scalar. Explora endpoints, prueba peticiones y genera código de cliente desde un único archivo de especificación.",
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
        "Cada endpoint de lista admite paginación basada en páginas, filtrado por campo y ordenación por defecto. Los metadatos de respuesta predecibles simplifican la construcción de clientes.",
      icon: "code"
    }
  ]
}
---

## Desarrollador primero

La API REST es la columna vertebral de Glossia. El panel de control, la CLI y el [servidor MCP](/features/mcp-server) consumen los mismos endpoints. Cuando añadimos una funcionalidad, aterriza primero en la API y se expone en todos los demás lugares a partir de ahí.

Esto significa que nunca estás limitado por la interfaz de usuario. Cualquier flujo de trabajo que puedas imaginar, desde integraciones CI/CD hasta paneles personalizados, se puede construir sobre la misma interfaz estable y documentada.

## Autenticación

Glossia usa OAuth 2.1 con PKCE para toda la autenticación de API. El flujo admite tanto clientes de primera parte como clientes de terceros. Consulta la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran programáticamente en `/oauth/register` con sus URIs de redirección y tipos de concesión. Sin paso de aprobación manual, sin portal que haga clic.

**Código de autorización con PKCE** -- Los usuarios autorizan clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE asegura que los tokens se mantengan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida de los tokens** -- Los tokens de acceso pueden intercambiarse, inspeccionarse y revocarse a través de endpoints de OAuth estándar. La limitación de tasa en los endpoints de tokens protege contra fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. La [documentación de autenticación](/docs/reference/apis/authentication) cubre alcances, roles y la matriz completa de permisos en detalle.

**Alcances** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no puede modificarlas. Los alcances siguen el patrón `resource:action`: `account:read`, `organization:write`, `glossary:admin` para administración del glosario, y así sucesivamente.

**Políticas** verifican la relación entre el usuario y el recurso específico. Un token válido con el alcance correcto aún no puede acceder a una organización a la que no pertenece el usuario. Cada solicitud se comprueba contra ambas capas.

## Paginación, filtrado y ordenamiento

Todos los endpoints de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` y `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtra por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordena ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma en todos los recursos.

## OpenAPI y documentación interactiva

La especificación completa de OpenAPI 3.1 está disponible en `/api/openapi.json`. El [referencia de API interactiva](/docs/reference/apis/rest) está impulsado por Scalar y te permite explorar endpoints, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier idioma pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que tus integraciones no se rompen cuando lanzamos nuevas funcionalidades.
