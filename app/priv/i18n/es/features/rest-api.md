%{
  title: "API REST",
  summary:
    "Una API REST orientada al desarrollador con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedes hacer en el panel, puedes hacerlo a través de la API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado en OpenAPI",
      description:
        "Una especificación completa OpenAPI 3.1 habilita la documentación interactiva a través de Scalar. Explora puntos finales, prueba solicitudes y genera código del cliente a partir de un solo archivo de especificación.",
      icon: "Libro abierto"
    },
    %{
      title: "OAuth 2.1 con PKCE",
      description:
        "Registro dinámico de clientes, flujo de código de autorización con PKCE, introspección de tokens y revocación. Los clientes de terceros se autentican de forma segura sin compartir secretos.",
      icon: "Llave redonda"
    },
    %{
      title: "Paginación y filtrado",
      description:
        "Todos los puntos finales de lista admiten paginación por páginas, filtrado por campo y ordenamiento por defecto. Los metadatos de respuesta predecibles facilitan la creación de clientes.",
      icon: "Código"
    }
  ]
}
---
## Desarrollador primero

La API REST es el núcleo de Glossia. El panel de control, la CLI, y el [servidor MCP](/features/mcp-server) todos consumen los mismos endpoints. Cuando añadimos una característica, llega primero a la API y se expone en todos los demás lugares desde allí.

Esto significa que nunca estás limitado por la IU. Cualquier flujo de trabajo que puedas imaginar, desde integraciones de CI/CD hasta paneles personalizados, se puede construir sobre la misma interfaz estable y documentada.

## Autenticación

Glossia usa OAuth 2.1 con PKCE para toda la autenticación de API. El flujo soporta tanto clientes de primera parte como terceros. Ver la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran de manera programática en `/oauth/register` con sus URIs de redirección y tipos de concesión. Sin pasos de aprobación manual, ni portal por el que debas navegar.

**Código de autorización con PKCE** -- Los usuarios autorizan a los clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE garantiza que los tokens permanezcan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida de los tokens** -- Los tokens de acceso pueden intercambiarse, introspeccionarse y revocarse a través de los puntos finales OAuth estándar. La limitación de tasa en los puntos finales de tokens protege contra ataques de fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. La [documentación de autenticación](/docs/reference/apis/authentication) aborda los alcances, roles y la matriz de permisos completa en detalle.

**Alcances** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer las configuraciones de voz pero no modificarlas. Los alcances siguen el `resource:action` patrón: `account:read`, `organization:write`, `glossary:admin` para la administración de glosario, y así sucesivamente.

**Políticas** verificar la relación entre el usuario y el recurso específico. Un token válido con el alcance correcto aún no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se verifica contra ambas capas.

## Paginación, filtrado y ordenación

Todos los endpoints de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, y `has_previous_page?` para que los clientes puedan construir controles de paginación sin tener que adivinar.

Filtrar por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordenar de forma ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma en todos los recursos.

## OpenAPI y documentación interactiva

La especificación completa OpenAPI 3.1 está disponible en `/api/openapi.json`. La [referencia API interactiva](/docs/reference/apis/rest) está impulsada por Scalar y te permite explorar endpoints, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier lenguaje se pueden generar a partir de la especificación. El contrato está versionado y es estable, por lo que tus integraciones no se rompen cuando lanzamos nuevas características.