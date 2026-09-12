%{
  title: "API REST",
  summary:
    "Una API REST centrada en desarrolladores con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puedes hacer en el panel de control también lo puedes hacer a través de la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Empezar",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Documentado en OpenAPI",
      description:
        "Una especificación completa de OpenAPI 3.1 habilita la documentación interactiva mediante Scalar. Explora endpoints, prueba solicitudes y genera código de cliente desde un solo archivo de especificación.",
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
        "Todos los endpoints de lista admiten paginación basada en páginas, filtrado por campo y ordenamiento sin configuración. Los metadatos de respuesta predecibles facilitan la construcción de clientes.",
      icon: "code"
    }
  ]
}
---
## Desarrollador primero

La API REST es la columna vertebral de Glossia. El panel, la CLI y el [servidor MCP](/features/mcp-server) todos consumen los mismos puntos finales. Cuando añadimos una característica, esta se implementa en la API primero y se expone en todos los demás lugares desde allí.

Esto significa que nunca estarás limitado por la interfaz. Cualquier flujo que puedas imaginar, desde integraciones de CI/CD hasta paneles personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia usa OAuth 2.1 con PKCE para toda la autenticación de API. El flujo admite tanto clientes de primera parte como de tercera parte. Consulte la [documentación de autenticación y autorización](/docs/reference/apis/authentication) para el recorrido completo.

**Registro dinámico de clientes** -- Los clientes se registran programáticamente en `/oauth/register` con sus URIs de redirección y tipos de concesión. Sin paso de aprobación manual, ni portal que deba navegarse.

**Código de autorización con PKCE** -- Los usuarios autorizan clientes a través de una pantalla de consentimiento basada en el navegador. La extensión PKCE garantiza que los tokens permanezcan seguros incluso para clientes públicos que no puedan almacenar un secreto.

**Ciclo de vida de los tokens** -- Los tokens de acceso pueden intercambiarse, introspeccionarse y revocarse a través de los puntos finales estándar de OAuth. La limitación de tasa en los puntos finales de token protege contra ataques de fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. Los [documentos de autenticación](/docs/reference/apis/authentication) cubren los alcances, roles y la matriz completa de permisos en detalle.

**Alcances** definen qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz pero no modificarlas. Los alcances siguen el `resource:action` patrón: `account:read`El documento reensamblado previamente falló la validación: la recuperación de texto literal Markdown debe devolver un array de cadenas JSON de longitud coincidente. `organization:write`, `glossary:admin` para la administración de terminología, y así sucesivamente.

**Políticas** Verificar la relación entre el usuario y el recurso específico. Un token válido con el alcance correcto aún no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se verifica contra ambas capas.

## Paginación, filtrado y ordenamiento

Todos los puntos finales de lista devuelven resultados paginados con metadatos consistentes:

Cada respuesta incluye `total_count`“ `total_pages`” `current_page`El documento reensamblado previamente falló la validación: la recuperación de texto literal de Markdown devolvió JSON inválido `page_size`El documento reensamblado previamente falló la validación: la recuperación de texto literal de Markdown devolvió un JSON inválido `has_next_page?`, y `has_previous_page?` para que los clientes puedan construir controles de paginación sin adivinar.

Filtrar por cualquier campo indexado usando `filters[field]=value` parámetros de consulta. Ordenar ascendente o descendente con `order_by[]` parámetros. La interfaz es la misma en todos los recursos.

## OpenAPI y documentación interactiva

La especificación OpenAPI 3.1 completa está disponible en `/api/openapi.json`. La [referencia interactiva de la API](/docs/reference/apis/rest) está impulsada por Scalar y te permite explorar endpoints, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

Las bibliotecas de cliente en cualquier idioma pueden generarse a partir de la especificación. El contrato está versionado y estable, por lo que tus integraciones no se rompen cuando lanzamos nuevas características.