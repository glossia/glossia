%{
  title: "API REST",
  summary:
    "Una API REST enfocada en desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización a nivel granular. Todo lo que puedas hacer en el panel de control, puedes hacerlo a través de la API.",
  order: 4,
  icon: "Terminal",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado en OpenAPI",
      description:
        "Una especificación completa de OpenAPI 3.1 habilita documentación interactiva a través de Scalar. Explora endpoints, prueba solicitudes y genera código de cliente desde un único archivo de especificación.",
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
        "Cada endpoint de lista admite paginación basada en página, filtrado de campos y clasificación de forma nativa. Los metadatos de respuesta predecibles facilitan la creación de clientes.",
      icon: "Código"
    }
  ]
}
---
## Desarrolladores primero

La REST API es la columna vertebral de Glossia. El panel de control, la CLI y el [servidor MCP](/features/mcp-server) todos consumen los mismos puntos finales. Cuando añadimos una funcionalidad, esta aterriza primero en la API y se replica en todos los demás lugares desde allí.

Esto significa que nunca estarás limitado por la interfaz de usuario. Cualquier flujo de trabajo que puedas imaginar, desde integraciones CI/CD hasta tableros de control personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia utiliza OAuth 2.1 con PKCE para toda la autenticación de API. El flujo admite tanto clientes de primera parte como de terceros. Consulta la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran de forma programática en `/oauth/register` con sus URIs de redirección y tipos de autorización. Sin paso de aprobación manual, sin portal para navegar.

**Código de autorización con PKCE** -- Los usuarios autorizan clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE garantiza que los tokens permanezcan seguros incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida del token** -- Los tokens de acceso pueden intercambiarse, introspectarse y revocarse a través de puntos finales estándar de OAuth. La limitación de tasa en los puntos finales de tokens protege contra fuerza bruta.

## Autorización

Control de acceso utiliza dos capas. La [documentación de autenticación](/docs/reference/apis/authentication) cubre los ámbitos, roles y la matriz de permisos completa en detalle.

**Ámbitos** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no modificarlas. Los ámbitos siguen el `resource:action` patrón): `account:read`, `organization:write`, `glossary:admin` ,para la administración de terminología, y así sucesivamente.

**Políticas** verificar la relación entre el usuario y el recurso específico. Un token válido con el alcance adecuado aún no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se valida contra ambas capas.

## Paginación, filtrado y ordenación

Todos los puntos finales de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`( `total_pages`) `current_page`, `page_size`El documento ensamblado falló la validación previamente: la recuperación de texto literal de Markdown debe retornar un array de cadenas JSON de longitud coincidente. `has_next_page?`y `has_previous_page?` para que los clientes puedan crear controles de paginación sin adivinar.

Filtrar por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordenar ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma en todos los recursos.

## OpenAPI y documentación interactiva

La especificación completa de OpenAPI 3.1 está disponible en `/api/openapi.json`. El [referencia interactiva de API](/docs/reference/apis/rest) está impulsado por Scalar y te permite explorar puntos finales, revisar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier lenguaje pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que sus integraciones no se rompen al lanzar nuevas características.