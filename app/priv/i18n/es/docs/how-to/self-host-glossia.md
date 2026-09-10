%{
  title: "Auto-alojar Glossia",
  summary:
    "Instala Glossia en tu propio clúster de Kubernetes con el gráfico Helm incluido, para que tu equipo ejecute el sistema operativo para idiomas en su propia infraestructura.",
  category: "Guías",
  order: 2
}
---
Glossia es de código abierto bajo la [Licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y utilizarlo para el uso interno de tu organización. Lo único que la licencia no permite es ofrecerlo a terceros como un producto alojado o SaaS que compita con el servicio alojado en glossia.ai.

Esta guía te lleva desde un clúster de Kubernetes vacío hasta una instancia de Glossia en funcionamiento.

## Antes de comenzar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar diagramas Helm (v1.28 o más reciente)
- `helm` y `kubectl` localmente
- Un dominio al que puedes apuntar al ingress del clúster
- Un proveedor OpenID Connect o relé SMTP para autenticación (Glossia soporta ambos)

El diagrama Helm incluye Postgres (mediante [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (mediante el [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) para que no necesites bases de datos externas. Si prefieres traerlas tú mismo, ambas pueden desactivarse en `values.yaml`.

## Instala los operadores

Instala los operadores que coincidan con los componentes que planeas habilitar. Al menos:

- [operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para la base de datos de la aplicación
- [operador ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) para la base de datos analítica
- Un controlador Ingress (por ejemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si desea TLS automático

## Instale el chart de Glossia

Clone el repositorio, luego instale el chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Proporcione los secretos de la aplicación

Cree un Kubernetes Secret nombrado `glossia-app-env` con al menos estas claves:

| Clave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | clave de firma de sesión de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | protección de token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Autenticación básica para `/ops` tableros |
| `RELEASE_COOKIE` | Cookie de distribución de Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` | Configuración de correo electrónico saliente |

Puedes provisionarlos directamente, usa [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conecte el chart a su gestor de secretos a través de [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del chart.

## ¿Qué contiene el chart?

- La aplicación web de Glossia
- Postgres para datos de la aplicación (opcional, activado por defecto)
- ClickHouse para analítica (opcional, activado por defecto)
- Trabajadores de fondo para trabajos de traducción, que se ejecutan como Jobs de Kubernetes para que sobrevivan a los despliegues en rodillo

## Dónde ir a continuación

- El [README del Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, más notas sobre copias de seguridad, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) una vez que la instancia esté en ejecución para que las traducciones puedan llamar a un LLM.
- Reportar problemas o sugerir mejoras en la [Repositorio de GitHub](https://github.com/glossia/glossia).