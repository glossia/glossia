%{
  title: "API REST",
  summary: "Una API REST diseñada para desarrolladores, con documentación OpenAPI, autenticación OAuth 2.1 y autorización granular. Todo lo que puede hacer en el panel de control también puede hacerlo mediante la API.",
  order: 4,
  icon: "terminal",
  hero_cta_text: "Comenzar",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Documentada con OpenAPI", description: "Una especificación completa de OpenAPI 3.1 proporciona documentación interactiva mediante Scalar. Explore los endpoints, pruebe solicitudes y genere código de cliente a partir de un único archivo de especificación.", icon: "book-open"},
    %{title: "OAuth 2.1 con PKCE", description: "Registro dinámico de clientes, flujo de código de autorización con PKCE, introspección de tokens y revocación. Los clientes de terceros se autentican de forma segura sin compartir secretos.", icon: "key-round"},
    %{title: "Paginación y filtrado", description: "Todos los endpoints de listado admiten de forma predeterminada paginación por páginas, filtrado por campos y ordenación. Los metadatos de respuesta predecibles facilitan el desarrollo de clientes.", icon: "code"}
  ]
}
---
## Primero para desarrolladores

La API REST es la base de Glossia. El panel, la CLI y el [servidor MCP](/features/mcp-server) consumen los mismos endpoints. Cuando añadimos una funcionalidad, primero se incorpora a la API y, desde allí, se ofrece en todas las demás interfaces.

Esto significa que la interfaz de usuario nunca limita sus posibilidades. Cualquier flujo de trabajo que pueda imaginar, desde integraciones de CI/CD hasta paneles personalizados, puede construirse sobre la misma interfaz estable y documentada.

## Autenticación

Glossia utiliza OAuth 2.1 con PKCE para toda la autenticación de la API. El flujo admite tanto clientes propios como de terceros. Consulte la [documentación sobre autenticación y autorización](/docs/reference/apis/authentication) para ver el proceso completo.

**Registro dinámico de clientes** -- Los clientes se registran mediante programación en `/oauth/register` con sus URI de redirección y tipos de concesión. No se requiere aprobación manual ni navegar por un portal.

**Código de autorización con PKCE** -- Los usuarios autorizan a los clientes mediante una pantalla de consentimiento en el navegador. La extensión PKCE garantiza la seguridad de los tokens, incluso para clientes públicos que no pueden almacenar un secreto.

**Ciclo de vida de los tokens** -- Los tokens de acceso pueden intercambiarse, inspeccionarse y revocarse mediante endpoints estándar de OAuth. La limitación de frecuencia en los endpoints de tokens protege contra ataques de fuerza bruta.

## Autorización

El control de acceso utiliza dos capas. La [documentación sobre autenticación](/docs/reference/apis/authentication) detalla los ámbitos, los roles y la matriz completa de permisos.

**Los ámbitos** definen a qué categorías de recursos puede acceder un token. Un token con `voice:read` puede leer configuraciones de voz, pero no modificarlas. Los ámbitos siguen el patrón `resource:action`: `account:read`, `organization:write`, `glossary:admin` para la administración de terminologia, entre otros.

**Las políticas** verifican la relación entre el usuario y el recurso específico. Aunque un token sea válido y tenga el ámbito adecuado, no puede acceder a una organización a la que el usuario no pertenece. Cada solicitud se comprueba en ambas capas.

## Paginación, filtrado y ordenación

Todos los endpoints de listas devuelven resultados paginados con metadatos coherentes:

Cada respuesta incluye `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` y `has_previous_page?`, por lo que los clientes pueden crear controles de paginación sin hacer suposiciones.

Filtre por cualquier campo indexado mediante parámetros de consulta `filters[field]=value`. Ordene de forma ascendente o descendente con parámetros `order_by[]`. La interfaz es la misma para todos los recursos.

## OpenAPI y documentación interactiva

La especificación completa de OpenAPI 3.1 está disponible en `/api/openapi.json`. La [referencia interactiva de la API](/docs/reference/apis/rest), basada en Scalar, permite explorar endpoints, inspeccionar esquemas y realizar solicitudes de prueba directamente desde el navegador.

A partir de la especificación se pueden generar bibliotecas cliente en cualquier lenguaje. El contrato está versionado y es estable, por lo que sus integraciones no dejan de funcionar cuando publicamos nuevas funcionalidades.